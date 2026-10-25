"""L4/L5 FastAPI Routers for HomeReminder API."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.primitives import ProductCategory
from app.database import get_db
from app.schemas.item import (
    ProductItemCreate,
    ProductItemResponse,
    ProductItemUpdate,
    StoreOfferSchema,
    UsageAnalyzeRequest,
    UsageAnalyzeResponse,
)
from app.services.inventory_service import InventoryCommandService
from app.services.usage_oracle import estimate_usage_smart

router = APIRouter(prefix="/api/v1", tags=["inventory"])

DbDep = Annotated[AsyncSession, Depends(get_db)]


@router.post("/usage/analyze", response_model=UsageAnalyzeResponse)
async def analyze_usage(payload: UsageAnalyzeRequest) -> UsageAnalyzeResponse:
    """AI & Reference Oracle endpoint to preview daily consumption and depletion date."""
    res = await estimate_usage_smart(
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
    return UsageAnalyzeResponse(
        daily_usage_amount=res.daily_usage_amount,
        estimated_total_days=res.estimated_total_days,
        expected_end_date=res.expected_end_date,
        reminder_date=res.reminder_date,
        explanation=res.explanation,
        used_ai=res.used_ai,
    )


@router.post("/items", response_model=ProductItemResponse, status_code=status.HTTP_201_CREATED)
async def create_item(payload: ProductItemCreate, db: DbDep) -> ProductItemResponse:
    return await InventoryCommandService(db).create_item(payload)


@router.get("/items", response_model=list[ProductItemResponse])
async def list_items(
    db: DbDep,
    category: ProductCategory | None = None,
    only_restock_soon: bool = False,
    include_archived: bool = False,
) -> list[ProductItemResponse]:
    return await InventoryCommandService(db).list_items(
        category=category,
        only_restock_soon=only_restock_soon,
        include_archived=include_archived,
    )


@router.get("/items/{item_id}", response_model=ProductItemResponse)
async def get_item(item_id: int, db: DbDep) -> ProductItemResponse:
    item = await InventoryCommandService(db).get_item(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


@router.post("/items/{item_id}/restock", response_model=ProductItemResponse)
async def restock_item(item_id: int, db: DbDep) -> ProductItemResponse:
    item = await InventoryCommandService(db).restock_item(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


@router.patch("/items/{item_id}", response_model=ProductItemResponse)
async def update_item(item_id: int, payload: ProductItemUpdate, db: DbDep) -> ProductItemResponse:
    item = await InventoryCommandService(db).update_item(item_id, payload)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(item_id: int, db: DbDep) -> None:
    deleted = await InventoryCommandService(db).delete_item(item_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Item not found")


@router.get("/stores/search", response_model=list[StoreOfferSchema])
async def search_stores(
    db: DbDep,
    q: Annotated[str, Query(min_length=2, max_length=200)],
    live: bool = True,
) -> list[StoreOfferSchema]:
    """Searches Rossmann, Hebe, Allegro, and Ekodrogeria in Poland for a product."""
    return await InventoryCommandService(db).check_polish_stores_for_query(query=q, live_scrape=live)
