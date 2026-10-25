"""Self-contained verification runner for HomeReminder Backend (Oracle + PL Stores + FastAPI CRUD)."""

import asyncio
from datetime import date, timedelta

from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.primitives import PolishStore, ProductCategory, VolumeUnit
from app.database import Base, get_db
from app.main import create_app
from app.services.pl_store_scraper import build_store_search_url
from app.services.usage_oracle import calculate_usage_oracle


async def run_all_checks() -> None:
    # 1. Verify Usage Oracle
    purchase = date(2026, 10, 25)
    res = calculate_usage_oracle(
        product_name="Гель для умывания CeraVe",
        category=ProductCategory.COSMETICS,
        total_volume=400.0,
        unit=VolumeUnit.ML,
        usage_description="Умываемся вдвоем утром и вечером",
        purchase_date=purchase,
        reminder_days_before=5,
    )
    assert res.daily_usage_amount == 8.0, f"Expected 8.0, got {res.daily_usage_amount}"
    assert res.estimated_total_days == 50, f"Expected 50, got {res.estimated_total_days}"
    assert res.expected_end_date == purchase + timedelta(days=50)
    print(f"[PASS] UsageOracle: {res.explanation}")

    # 2. Verify Polish Store URLs
    q = "CeraVe Żel oczyszczający 473ml"
    for store in (
        PolishStore.ROSSMANN,
        PolishStore.HEBE,
        PolishStore.ALLEGRO,
        PolishStore.EKODROGERIA,
    ):
        url = build_store_search_url(store, q)
        assert url.startswith("https://")
    print("[PASS] Polish Store URLs (Rossmann, Hebe, Allegro, Ekodrogeria) verified.")

    # 3. Verify FastAPI CRUD + Restock + Store Search
    test_engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    session_factory = async_sessionmaker(test_engine, expire_on_commit=False)

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    app = create_app()

    async def override_get_db():
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post(
            "/api/v1/items",
            json={
                "name": "CeraVe Foaming Cleanser",
                "brand": "CeraVe",
                "category": "cosmetics",
                "total_volume": 400,
                "unit": "ml",
                "purchase_date": str(date.today()),
                "usage_description": "Гель для умывания, умываемся вдвоем утром и вечером",
                "reminder_days_before": 5,
                "preferred_store": "Hebe",
                "last_price_pln": 54.99,
            },
        )
        assert resp.status_code == 201, resp.text
        created = resp.json()
        assert created["estimated_total_days"] == 50
        assert {s["store"] for s in created["store_links"]} == {
            "Rossmann",
            "Hebe",
            "Allegro",
            "Ekodrogeria",
        }

        list_resp = await client.get("/api/v1/items")
        assert list_resp.status_code == 200
        assert len(list_resp.json()) == 1

        restock_resp = await client.post(f"/api/v1/items/{created['id']}/restock")
        assert restock_resp.status_code == 200

    await test_engine.dispose()
    print("[PASS] FastAPI Inventory CRUD, Restock & Polish Store Links passed 100%!")


if __name__ == "__main__":
    asyncio.run(run_all_checks())
