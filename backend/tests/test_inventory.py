"""Unit and integration tests for HomeReminder Backend (Usage Oracle, PL Stores, API)."""

from datetime import date, timedelta

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.primitives import PolishStore, ProductCategory, VolumeUnit
from app.database import Base, get_db
from app.main import create_app
from app.services.pl_store_scraper import build_store_search_url
from app.services.usage_oracle import calculate_usage_oracle

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"
test_engine = create_async_engine(TEST_DATABASE_URL)
TestingSessionLocal = async_sessionmaker(test_engine, expire_on_commit=False)


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def client():
    app = create_app()

    async def override_get_db():
        async with TestingSessionLocal() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac


def test_usage_oracle_face_wash_two_people():
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
    # 2 ml per wash * 2 times/day * 2 people = 8 ml/day -> 400 / 8 = 50 days
    assert res.daily_usage_amount == 8.0
    assert res.estimated_total_days == 50
    assert res.expected_end_date == purchase + timedelta(days=50)
    assert res.reminder_date == purchase + timedelta(days=45)


def test_polish_store_urls():
    q = "CeraVe Żel oczyszczający 473ml"
    rossmann = build_store_search_url(PolishStore.ROSSMANN, q)
    hebe = build_store_search_url(PolishStore.HEBE, q)
    allegro = build_store_search_url(PolishStore.ALLEGRO, q)
    ekodrogeria = build_store_search_url(PolishStore.EKODROGERIA, q)

    assert "rossmann.pl/szukaj?Search=" in rossmann
    assert "hebe.pl/szukaj?q=" in hebe
    assert "allegro.pl/listing?string=" in allegro
    assert "ekodrogeria.pl/pl/searchquery/" in ekodrogeria


@pytest.mark.asyncio
async def test_create_and_list_inventory_item(client: AsyncClient):
    payload = {
        "name": "CeraVe Foaming Cleanser",
        "brand": "CeraVe",
        "category": "cosmetics",
        "total_volume": 473,
        "unit": "ml",
        "purchase_date": str(date.today()),
        "usage_description": "Гель для умывания, 2 раза в день один человек",
        "reminder_days_before": 7,
        "preferred_store": "Hebe",
        "last_price_pln": 54.99,
    }
    resp = await client.post("/api/v1/items", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "CeraVe Foaming Cleanser"
    assert data["estimated_total_days"] > 0
    assert len(data["store_links"]) == 4
    stores = {s["store"] for s in data["store_links"]}
    assert stores == {"Rossmann", "Hebe", "Allegro", "Ekodrogeria"}

    list_resp = await client.get("/api/v1/items")
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1
