from uuid import UUID

from fastapi import APIRouter, Depends, File, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.receipt import (
    ReceiptItemRead,
    ReceiptItemUpdateRequest,
    ReceiptListResponse,
    ReceiptRead,
    ReceiptUploadResponse,
)
from app.services.receipt_service import ReceiptService

router = APIRouter(prefix="/receipts", tags=["receipts"])


@router.post("/upload", response_model=ReceiptUploadResponse, status_code=status.HTTP_202_ACCEPTED)
async def upload_receipt(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    file_bytes = await file.read()
    service = ReceiptService(db)
    receipt = await service.upload(
        user_id=str(current_user.id),
        file_bytes=file_bytes,
        content_type=file.content_type or "application/octet-stream",
        filename=file.filename or "receipt.jpg",
    )

    # Import kept local to avoid loading Celery/broker config at API startup
    # for routes that never touch it.
    from app.services.receipt_tasks import process_receipt_task

    process_receipt_task.delay(str(receipt.id))

    return ReceiptUploadResponse(id=receipt.id, status=receipt.status)


@router.get("", response_model=ReceiptListResponse)
async def list_receipts(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = ReceiptService(db)
    items, total = await service.list_for_user(str(current_user.id), page, page_size)
    return ReceiptListResponse(items=items, total=total, page=page, page_size=page_size)


@router.get("/{receipt_id}", response_model=ReceiptRead)
async def get_receipt(
    receipt_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = ReceiptService(db)
    return await service.get(receipt_id, str(current_user.id))


@router.patch("/{receipt_id}/items/{item_id}", response_model=ReceiptItemRead)
async def update_receipt_item(
    receipt_id: UUID,
    item_id: UUID,
    payload: ReceiptItemUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = ReceiptService(db)
    return await service.update_item(receipt_id, item_id, str(current_user.id), payload)
