"""L3 Service & Command Engine for HomeReminder Inventory."""

from __future__ import annotations

from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.primitives import PolishStore, ProductCategory, VolumeUnit
from app.models.item import ProductItemModel
from app.schemas.item import (
    ProductItemCreate,
    ProductItemResponse,
    ProductItemUpdate,
    StoreOfferSchema,
)
from app.services.pl_store_scraper import build_store_search_url, search_polish_stores
from app.services.usage_oracle import estimate_usage_smart


def _enrich_item_response(row: ProductItemModel, today: date | None = None) -> ProductItemResponse:
    ref_date = today or date.today()
    days_remaining = (row.expected_end_date - ref_date).days
    total_days = max(1, row.estimated_total_days)
    pct = max(0.0, min(100.0, round((days_remaining / total_days) * 100.0, 1)))
    needs_restock = days_remaining <= row.reminder_days_before

    query_str = f"{row.brand} {row.name}".strip() if row.brand else row.name
    store_links = [
        StoreOfferSchema(
            store=st,
            product_title=query_str,
            price_pln=row.last_price_pln if row.preferred_store == st.value else None,
            currency="PLN",
            in_stock=True,
            search_url=build_store_search_url(st, query_str),
            note=f"Купить в {st.value}",
        )
        for st in (
            PolishStore.ROSSMANN,
            PolishStore.HEBE,
            PolishStore.ALLEGRO,
            PolishStore.EKODROGERIA,
        )
    ]

    return ProductItemResponse(
        id=row.id,
        name=row.name,
        brand=row.brand,
        category=ProductCategory(row.category),
        total_volume=row.total_volume,
        unit=VolumeUnit(row.unit),
        purchase_date=row.purchase_date,
        usage_description=row.usage_description,
        daily_usage_amount=row.daily_usage_amount,
        estimated_total_days=row.estimated_total_days,
        expected_end_date=row.expected_end_date,
        reminder_date=row.reminder_date,
        reminder_days_before=row.reminder_days_before,
        ai_explanation=row.ai_explanation,
        preferred_store=row.preferred_store,
        last_price_pln=row.last_price_pln,
        store_url=row.store_url,
        is_archived=row.is_archived,
        created_at=row.created_at,
        days_remaining=days_remaining,
        remaining_percentage=pct,
        needs_restock_soon=needs_restock,
        store_links=store_links,
    )


class InventoryCommandService:
    """Implements L3 Command Pattern for all inventory & price operations."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_item(self, payload: ProductItemCreate) -> ProductItemResponse:
        estimate = await estimate_usage_smart(
            product_name=payload.name,
            category=payload.category,
            total_volume=payload.total_volume,
            unit=payload.unit,
            usage_description=payload.usage_description,
            purchase_date=payload.purchase_date,
            reminder_days_before=payload.reminder_days_before,
            gemini_api_key=settings.gemini_api_key,
            gemini_model=settings.gemini_model,
        )

        total_days = payload.override_total_days or estimate.estimated_total_days
        expected_end = payload.purchase_date + timedelta(days=total_days)
        reminder_dt = max(
            payload.purchase_date,
            expected_end - timedelta(days=payload.reminder_days_before),
        )
        daily_usage = round(payload.total_volume / max(1, total_days), 2)

        pref_store = payload.preferred_store or PolishStore.ROSSMANN
        query_str = f"{payload.brand} {payload.name}".strip() if payload.brand else payload.name
        store_url = build_store_search_url(pref_store, query_str)

        row = ProductItemModel(
            name=payload.name,
            brand=payload.brand,
            category=payload.category.value,
            total_volume=payload.total_volume,
            unit=payload.unit.value,
            purchase_date=payload.purchase_date,
            usage_description=payload.usage_description,
            daily_usage_amount=daily_usage,
            estimated_total_days=total_days,
            expected_end_date=expected_end,
            reminder_date=reminder_dt,
            reminder_days_before=payload.reminder_days_before,
            ai_explanation=estimate.explanation,
            preferred_store=pref_store.value,
            last_price_pln=payload.last_price_pln,
            store_url=store_url,
        )
        self.db.add(row)
        await self.db.commit()
        await self.db.refresh(row)
        return _enrich_item_response(row)

    async def list_items(
        self,
        category: ProductCategory | None = None,
        only_restock_soon: bool = False,
        include_archived: bool = False,
    ) -> list[ProductItemResponse]:
        stmt = select(ProductItemModel).order_by(ProductItemModel.expected_end_date.asc())
        if not include_archived:
            stmt = stmt.where(ProductItemModel.is_archived.is_(False))
        if category is not None:
            stmt = stmt.where(ProductItemModel.category == category.value)

        result = await self.db.execute(stmt)
        rows = list(result.scalars().all())
        enriched = [_enrich_item_response(r) for r in rows]
        if only_restock_soon:
            enriched = [item for item in enriched if item.needs_restock_soon]
        return enriched

    async def get_item(self, item_id: int) -> ProductItemResponse | None:
        row = await self.db.get(ProductItemModel, item_id)
        if row is None:
            return None
        return _enrich_item_response(row)

    async def restock_item(self, item_id: int, new_purchase_date: date | None = None) -> ProductItemResponse | None:
        """Command: item.restock — resets purchase date to today when user buys a fresh bottle."""
        row = await self.db.get(ProductItemModel, item_id)
        if row is None:
            return None
        p_date = new_purchase_date or date.today()
        row.purchase_date = p_date
        row.expected_end_date = p_date + timedelta(days=row.estimated_total_days)
        row.reminder_date = max(
            p_date,
            row.expected_end_date - timedelta(days=row.reminder_days_before),
        )
        await self.db.commit()
        await self.db.refresh(row)
        return _enrich_item_response(row)

    async def update_item(self, item_id: int, payload: ProductItemUpdate) -> ProductItemResponse | None:
        row = await self.db.get(ProductItemModel, item_id)
        if row is None:
            return None

        if payload.name is not None:
            row.name = payload.name
        if payload.usage_description is not None:
            row.usage_description = payload.usage_description
        if payload.reminder_days_before is not None:
            row.reminder_days_before = payload.reminder_days_before
        if payload.preferred_store is not None:
            row.preferred_store = payload.preferred_store.value
        if payload.last_price_pln is not None:
            row.last_price_pln = payload.last_price_pln
        if payload.is_archived is not None:
            row.is_archived = payload.is_archived

        if payload.estimated_total_days is not None:
            row.estimated_total_days = payload.estimated_total_days
            row.daily_usage_amount = round(row.total_volume / max(1, payload.estimated_total_days), 2)

        row.expected_end_date = row.purchase_date + timedelta(days=row.estimated_total_days)
        row.reminder_date = max(
            row.purchase_date,
            row.expected_end_date - timedelta(days=row.reminder_days_before),
        )

        await self.db.commit()
        await self.db.refresh(row)
        return _enrich_item_response(row)

    async def delete_item(self, item_id: int) -> bool:
        row = await self.db.get(ProductItemModel, item_id)
        if row is None:
            return False
        await self.db.delete(row)
        await self.db.commit()
        return True

    async def check_polish_stores_for_query(
        self,
        query: str,
        live_scrape: bool = True,
    ) -> list[StoreOfferSchema]:
        offers = await search_polish_stores(query=query, live_scrape=live_scrape)
        return [
            StoreOfferSchema(
                store=o.store,
                product_title=o.product_title,
                price_pln=o.price_pln,
                currency=o.currency,
                in_stock=o.in_stock,
                search_url=o.search_url,
                note=o.note,
            )
            for o in offers
        ]
