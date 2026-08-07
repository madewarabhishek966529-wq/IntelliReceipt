import logging
from datetime import datetime
from uuid import UUID

import httpx

from app.db.sync_session import get_sync_db
from app.models.receipt import PaymentMethod, Receipt, ReceiptStatus
from app.models.receipt_item import ReceiptItem
from app.services.ai_extraction_service import AiExtractionService, ExtractionParseError
from app.services.celery_app import celery_app
from app.services.ocr_service import OcrService

logger = logging.getLogger(__name__)

# Items below this AI confidence trigger NEEDS_REVIEW instead of COMPLETED,
# so low-confidence extractions surface in the app for the user to fix
# rather than silently polluting price history with bad data.
REVIEW_CONFIDENCE_THRESHOLD = 0.55


def _download_image(image_url: str) -> bytes | None:
    if image_url.startswith("local://"):
        # Storage isn't configured (dev/test environment) — nothing to fetch.
        return None
    try:
        response = httpx.get(image_url, timeout=30.0)
        response.raise_for_status()
        return response.content
    except httpx.HTTPError as exc:
        logger.warning("Failed to download receipt image %s: %s", image_url, exc)
        return None


def _parse_payment_method(value: str | None) -> PaymentMethod | None:
    if value is None:
        return None
    try:
        return PaymentMethod(value)
    except ValueError:
        return None


@celery_app.task(name="receipts.process_receipt", bind=True, max_retries=2)
def process_receipt_task(self, receipt_id: str) -> None:
    """Runs OCR + AI extraction for a single receipt and persists the
    results. Triggered right after upload; also safe to re-trigger
    manually (e.g. a "retry" button in the app) since it's idempotent
    per-receipt (existing items are not duplicated on retry because the
    caller is expected to have cleared them first — see note below).
    """
    db = get_sync_db()
    try:
        receipt = db.get(Receipt, UUID(receipt_id))
        if receipt is None:
            logger.error("process_receipt_task: receipt %s not found", receipt_id)
            return

        receipt.status = ReceiptStatus.PROCESSING
        db.commit()

        if receipt.image_url is None:
            receipt.status = ReceiptStatus.FAILED
            db.commit()
            return

        image_bytes = _download_image(receipt.image_url)
        if image_bytes is None:
            receipt.status = ReceiptStatus.FAILED
            db.commit()
            return

        raw_text = OcrService().extract_text(image_bytes)
        receipt.raw_ocr_text = raw_text

        try:
            extracted = AiExtractionService().extract(raw_text)
        except ExtractionParseError as exc:
            logger.warning("AI extraction parse failure for receipt %s: %s", receipt_id, exc)
            receipt.status = ReceiptStatus.NEEDS_REVIEW
            db.commit()
            return

        receipt.invoice_number = extracted.invoice_number
        receipt.purchase_date = extracted.purchase_date
        receipt.purchase_time = extracted.purchase_time
        receipt.payment_method = _parse_payment_method(extracted.payment_method)
        receipt.subtotal = extracted.subtotal
        receipt.tax_amount = extracted.tax_amount
        receipt.discount_amount = extracted.discount_amount
        receipt.total_amount = extracted.total_amount

        needs_review = len(extracted.items) == 0

        for item in extracted.items:
            db.add(
                ReceiptItem(
                    receipt_id=receipt.id,
                    raw_text=item.raw_text,
                    display_name=item.display_name,
                    quantity=item.quantity,
                    unit=item.unit,
                    mrp=item.mrp,
                    discount=item.discount,
                    tax=item.tax,
                    final_price=item.final_price,
                    ai_confidence=item.confidence,
                )
            )
            if item.confidence < REVIEW_CONFIDENCE_THRESHOLD:
                needs_review = True

        receipt.status = ReceiptStatus.NEEDS_REVIEW if needs_review else ReceiptStatus.COMPLETED
        db.commit()

    except Exception as exc:  # noqa: BLE001 - top-level task guard
        db.rollback()
        logger.exception("process_receipt_task failed for %s", receipt_id)
        receipt = db.get(Receipt, UUID(receipt_id))
        if receipt is not None:
            receipt.status = ReceiptStatus.FAILED
            db.commit()
        raise self.retry(exc=exc, countdown=10) from exc
    finally:
        db.close()
