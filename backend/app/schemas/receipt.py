from datetime import date, datetime, time
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.models.receipt import PaymentMethod, ReceiptStatus


class ReceiptItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    product_id: UUID | None = None
    raw_text: str
    display_name: str
    quantity: float
    unit: str | None = None
    mrp: float | None = None
    discount: float | None = None
    tax: float | None = None
    final_price: float
    ai_confidence: float | None = None


class ReceiptRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    store_id: UUID | None = None
    image_url: str | None = None
    invoice_number: str | None = None
    purchase_date: date | None = None
    purchase_time: time | None = None
    subtotal: float | None = None
    tax_amount: float | None = None
    discount_amount: float | None = None
    total_amount: float | None = None
    payment_method: PaymentMethod | None = None
    status: ReceiptStatus
    created_at: datetime
    items: list[ReceiptItemRead] = []


class ReceiptListItem(BaseModel):
    """Lighter payload for list views — omits line items."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    store_id: UUID | None = None
    image_url: str | None = None
    total_amount: float | None = None
    status: ReceiptStatus
    purchase_date: date | None = None
    created_at: datetime


class ReceiptUploadResponse(BaseModel):
    id: UUID
    status: ReceiptStatus
    message: str = "Receipt uploaded. Processing has started."


class ReceiptListResponse(BaseModel):
    items: list[ReceiptListItem]
    total: int
    page: int
    page_size: int


class ReceiptItemUpdateRequest(BaseModel):
    """Used for manual correction from the receipt edit screen."""

    display_name: str | None = Field(default=None, max_length=255)
    quantity: float | None = None
    mrp: float | None = None
    discount: float | None = None
    tax: float | None = None
    final_price: float | None = None
