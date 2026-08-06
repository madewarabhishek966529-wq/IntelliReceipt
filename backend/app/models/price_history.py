from __future__ import annotations

from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import Date, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.product import Product
    from app.models.store import Store


class PriceHistory(Base, UUIDMixin, TimestampMixin):
    """Append-only log of observed prices. Every completed receipt item
    that resolves to a [Product] writes one row here; price trend charts,
    increase-detection, and store comparison all read from this table
    rather than recomputing from raw receipts.
    """

    __tablename__ = "price_history"

    product_id: Mapped[str] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id"), nullable=False, index=True
    )
    store_id: Mapped[str | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("stores.id"), nullable=True, index=True
    )
    user_id: Mapped[str] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)

    price: Mapped[float] = mapped_column(Float, nullable=False)
    observed_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    product: Mapped["Product"] = relationship(back_populates="price_history")
    store: Mapped["Store | None"] = relationship()
