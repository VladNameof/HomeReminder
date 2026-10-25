"""L2 Pydantic v2 Schemas for API contracts."""

from datetime import date, datetime

from pydantic import BaseModel, Field

from app.core.primitives import PolishStore, ProductCategory, VolumeUnit


class UsageAnalyzeRequest(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    category: ProductCategory = ProductCategory.COSMETICS
    total_volume: float = Field(gt=0)
    unit: VolumeUnit = VolumeUnit.ML
    usage_description: str = Field(min_length=3, max_length=1000)
    purchase_date: date = Field(default_factory=date.today)
    reminder_days_before: int = Field(default=5, ge=1, le=60)


class UsageAnalyzeResponse(BaseModel):
    daily_usage_amount: float
    estimated_total_days: int
    expected_end_date: date
    reminder_date: date
    explanation: str
    used_ai: bool


class StoreOfferSchema(BaseModel):
    store: PolishStore
    product_title: str
    price_pln: float | None = None
    currency: str = "PLN"
    in_stock: bool = True
    search_url: str
    note: str


class ProductItemCreate(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    brand: str | None = Field(default=None, max_length=120)
    category: ProductCategory = ProductCategory.COSMETICS
    total_volume: float = Field(gt=0)
    unit: VolumeUnit = VolumeUnit.ML
    purchase_date: date = Field(default_factory=date.today)
    usage_description: str = Field(min_length=3, max_length=1000)
    reminder_days_before: int = Field(default=5, ge=1, le=60)
    preferred_store: PolishStore | None = None
    last_price_pln: float | None = Field(default=None, ge=0)
    # Optional manual override of days if user adjusted AI estimate
    override_total_days: int | None = Field(default=None, ge=1, le=3650)


class ProductItemUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=200)
    usage_description: str | None = Field(default=None, min_length=3, max_length=1000)
    estimated_total_days: int | None = Field(default=None, ge=1, le=3650)
    reminder_days_before: int | None = Field(default=None, ge=1, le=60)
    preferred_store: PolishStore | None = None
    last_price_pln: float | None = Field(default=None, ge=0)
    is_archived: bool | None = None


class ProductItemResponse(BaseModel):
    id: int
    name: str
    brand: str | None
    category: ProductCategory
    total_volume: float
    unit: VolumeUnit
    purchase_date: date
    usage_description: str
    daily_usage_amount: float
    estimated_total_days: int
    expected_end_date: date
    reminder_date: date
    reminder_days_before: int
    ai_explanation: str
    preferred_store: str | None
    last_price_pln: float | None
    store_url: str | None
    is_archived: bool
    created_at: datetime

    # Computed dynamic status fields
    days_remaining: int
    remaining_percentage: float
    needs_restock_soon: bool
    store_links: list[StoreOfferSchema]

    model_config = {"from_attributes": True}
