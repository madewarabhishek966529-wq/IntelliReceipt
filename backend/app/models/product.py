from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.price_history import PriceHistory
    from app.models.receipt_item import ReceiptItem


class Product(Base, UUIDMixin, TimestampMixin):
    """Canonical, AI-normalized product (e.g. 'Maggi Noodles') that many
    raw OCR line items and receipt items map onto. This is what price
    history and price-increase detection are computed against.
    """

    __tablename__ = "products"

    name: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    normalized_name: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    brand: Mapped[str | None] = mapped_column(String(255), nullable=True)
    category_id: Mapped[str | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("categories.id"), nullable=True
    )
    default_unit: Mapped[str | None] = mapped_column(String(20), nullable=True)
    barcode: Mapped[str | None] = mapped_column(String(64), unique=True, nullable=True)

    price_history: Mapped[list["PriceHistory"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )
    receipt_items: Mapped[list["ReceiptItem"]] = relationship(back_populates="product")
