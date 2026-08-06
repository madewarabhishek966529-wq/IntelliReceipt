from __future__ import annotations

import enum
from datetime import date, time
from typing import TYPE_CHECKING

from sqlalchemy import Date, Enum, Float, ForeignKey, String, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.receipt_item import ReceiptItem
    from app.models.store import Store
    from app.models.user import User


class ReceiptStatus(str, enum.Enum):
    PENDING = "pending"          # uploaded, OCR not yet run
    PROCESSING = "processing"    # OCR/AI extraction in progress
    NEEDS_REVIEW = "needs_review"  # low-confidence extraction
    COMPLETED = "completed"
    FAILED = "failed"


class PaymentMethod(str, enum.Enum):
    CASH = "cash"
    CARD = "card"
    UPI = "upi"
    WALLET = "wallet"
    OTHER = "other"


class Receipt(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "receipts"

    user_id: Mapped[str] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    store_id: Mapped[str | None] = mapped_column(UUID(as_uuid=True), ForeignKey("stores.id"), nullable=True)

    image_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    raw_ocr_text: Mapped[str | None] = mapped_column(String, nullable=True)

    invoice_number: Mapped[str | None] = mapped_column(String(100), nullable=True)
    purchase_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    purchase_time: Mapped[time | None] = mapped_column(Time, nullable=True)

    subtotal: Mapped[float | None] = mapped_column(Float, nullable=True)
    tax_amount: Mapped[float | None] = mapped_column(Float, nullable=True)
    discount_amount: Mapped[float | None] = mapped_column(Float, nullable=True)
    total_amount: Mapped[float | None] = mapped_column(Float, nullable=True)

    payment_method: Mapped[PaymentMethod | None] = mapped_column(
        Enum(PaymentMethod, name="payment_method_enum"), nullable=True
    )
    status: Mapped[ReceiptStatus] = mapped_column(
        Enum(ReceiptStatus, name="receipt_status_enum"),
        default=ReceiptStatus.PENDING,
        nullable=False,
    )

    user: Mapped["User"] = relationship(back_populates="receipts")
    store: Mapped["Store | None"] = relationship()
    items: Mapped[list["ReceiptItem"]] = relationship(
        back_populates="receipt", cascade="all, delete-orphan"
    )
