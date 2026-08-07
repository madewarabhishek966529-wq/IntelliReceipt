from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.receipt import Receipt, ReceiptStatus
from app.repositories.receipt_repository import ReceiptRepository
from app.schemas.receipt import ReceiptItemUpdateRequest
from app.services.storage_service import StorageService

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "application/pdf"}
MAX_UPLOAD_BYTES = 15 * 1024 * 1024  # 15 MB


class ReceiptService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.receipts = ReceiptRepository(db)
        self.storage = StorageService()

    async def upload(
        self,
        user_id: str,
        file_bytes: bytes,
        content_type: str,
        filename: str,
    ) -> Receipt:
        if content_type not in ALLOWED_CONTENT_TYPES:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail="Only JPEG, PNG, WEBP, or PDF receipts are supported",
            )
        if len(file_bytes) > MAX_UPLOAD_BYTES:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="File exceeds the 15MB upload limit",
            )

        image_url = await self.storage.upload_receipt_image(
            user_id=user_id,
            file_bytes=file_bytes,
            content_type=content_type,
            original_filename=filename,
        )

        receipt = await self.receipts.create(
            user_id=user_id,
            image_url=image_url,
            status=ReceiptStatus.PENDING,
        )
        return receipt

    async def get(self, receipt_id: UUID, user_id: str) -> Receipt:
        receipt = await self.receipts.get_by_id(receipt_id, user_id)
        if receipt is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Receipt not found")
        return receipt

    async def list_for_user(self, user_id: str, page: int, page_size: int):
        return await self.receipts.list_for_user(user_id, page, page_size)

    async def update_item(self, receipt_id: UUID, item_id: UUID, user_id: str, payload: ReceiptItemUpdateRequest):
        # Ownership check: item must belong to a receipt owned by this user.
        receipt = await self.get(receipt_id, user_id)
        item = next((i for i in receipt.items if i.id == item_id), None)
        if item is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Receipt item not found")

        return await self.receipts.update_item(
            item,
            display_name=payload.display_name,
            quantity=payload.quantity,
            mrp=payload.mrp,
            discount=payload.discount,
            tax=payload.tax,
            final_price=payload.final_price,
        )
