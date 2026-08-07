from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.receipt import Receipt, ReceiptStatus
from app.models.receipt_item import ReceiptItem


class ReceiptRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, **fields) -> Receipt:
        receipt = Receipt(**fields)
        self.db.add(receipt)
        await self.db.commit()
        await self.db.refresh(receipt)
        return receipt

    async def get_by_id(self, receipt_id: UUID | str, user_id: UUID | str) -> Receipt | None:
        result = await self.db.execute(
            select(Receipt)
            .options(selectinload(Receipt.items))
            .where(Receipt.id == receipt_id, Receipt.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def list_for_user(
        self, user_id: UUID | str, page: int = 1, page_size: int = 20
    ) -> tuple[list[Receipt], int]:
        count_result = await self.db.execute(
            select(func.count()).select_from(Receipt).where(Receipt.user_id == user_id)
        )
        total = count_result.scalar_one()

        result = await self.db.execute(
            select(Receipt)
            .where(Receipt.user_id == user_id)
            .order_by(Receipt.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        return list(result.scalars().all()), total

    async def update_status(self, receipt: Receipt, status: ReceiptStatus) -> Receipt:
        receipt.status = status
        await self.db.commit()
        await self.db.refresh(receipt)
        return receipt

    async def update_extracted_fields(self, receipt: Receipt, **fields) -> Receipt:
        for key, value in fields.items():
            setattr(receipt, key, value)
        await self.db.commit()
        await self.db.refresh(receipt)
        return receipt

    async def add_items(self, receipt_id: UUID | str, items: list[dict]) -> list[ReceiptItem]:
        rows = [ReceiptItem(receipt_id=receipt_id, **item) for item in items]
        self.db.add_all(rows)
        await self.db.commit()
        for row in rows:
            await self.db.refresh(row)
        return rows

    async def get_item(self, item_id: UUID | str) -> ReceiptItem | None:
        result = await self.db.execute(select(ReceiptItem).where(ReceiptItem.id == item_id))
        return result.scalar_one_or_none()

    async def update_item(self, item: ReceiptItem, **fields) -> ReceiptItem:
        for key, value in fields.items():
            if value is not None:
                setattr(item, key, value)
        await self.db.commit()
        await self.db.refresh(item)
        return item
