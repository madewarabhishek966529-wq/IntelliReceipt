from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import Float, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.product import Product
    from app.models.receipt import Receipt


class ReceiptItem(Base, UUIDMixin, TimestampMixin):
    """A single scanned line item. `raw_text` preserves exactly what OCR
    saw; `product_id` links to the AI-normalized canonical [Product] once
    extraction/matching has run.
    """

    __tablename__ = "receipt_items"

    receipt_id: Mapped[str] = mapped_column(
        UUID(as_uuid=True), ForeignKey("receipts.id"), nullable=False, index=True
    )
    product_id: Mapped[str | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id"), nullable=True, index=True
    )

    raw_text: Mapped[str] = mapped_column(String(500), nullable=False)
    display_name: Mapped[str] = mapped_column(String(255), nullable=False)

    quantity: Mapped[float] = mapped_column(Float, default=1.0)
    unit: Mapped[str | None] = mapped_column(String(20), nullable=True)
    mrp: Mapped[float | None] = mapped_column(Float, nullable=True)
    discount: Mapped[float | None] = mapped_column(Float, nullable=True)
    tax: Mapped[float | None] = mapped_column(Float, nullable=True)
    final_price: Mapped[float] = mapped_column(Float, nullable=False)

    ai_confidence: Mapped[float | None] = mapped_column(Float, nullable=True)

    receipt: Mapped["Receipt"] = relationship(back_populates="items")
    product: Mapped["Product | None"] = relationship(back_populates="receipt_items")
