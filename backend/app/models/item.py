"""L2 SQLAlchemy ORM Models for HomeReminder Inventory."""

from datetime import date, datetime, timezone

from sqlalchemy import Boolean, Date, DateTime, Float, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class ProductItemModel(Base):
    __tablename__ = "product_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    brand: Mapped[str | None] = mapped_column(String(120), nullable=True)
    category: Mapped[str] = mapped_column(String(40), nullable=False, default="cosmetics")
    total_volume: Mapped[float] = mapped_column(Float, nullable=False)
    unit: Mapped[str] = mapped_column(String(20), nullable=False, default="ml")
    purchase_date: Mapped[date] = mapped_column(Date, nullable=False)
    usage_description: Mapped[str] = mapped_column(Text, nullable=False)

    daily_usage_amount: Mapped[float] = mapped_column(Float, nullable=False)
    estimated_total_days: Mapped[int] = mapped_column(Integer, nullable=False)
    expected_end_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    reminder_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    reminder_days_before: Mapped[int] = mapped_column(Integer, nullable=False, default=5)
    ai_explanation: Mapped[str] = mapped_column(Text, nullable=False, default="")

    preferred_store: Mapped[str | None] = mapped_column(String(50), nullable=True)
    last_price_pln: Mapped[float | None] = mapped_column(Float, nullable=True)
    store_url: Mapped[str | None] = mapped_column(Text, nullable=True)

    is_archived: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
