from __future__ import annotations

import enum
from datetime import date

from sqlalchemy import Date, Enum, ForeignKey, JSON, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.session import Base
from app.models.base import TimestampMixin, UUIDMixin


class InsightPeriod(str, enum.Enum):
    WEEKLY = "weekly"
    MONTHLY = "monthly"


class Insight(Base, UUIDMixin, TimestampMixin):
    """Persisted AI-generated report so weekly/monthly summaries don't
    need to be regenerated on every dashboard visit.
    """

    __tablename__ = "insights"

    user_id: Mapped[str] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    period: Mapped[InsightPeriod] = mapped_column(Enum(InsightPeriod, name="insight_period_enum"), nullable=False)
    period_start: Mapped[date] = mapped_column(Date, nullable=False)
    period_end: Mapped[date] = mapped_column(Date, nullable=False)

    summary: Mapped[str] = mapped_column(String(2000), nullable=False)
    highlights: Mapped[list] = mapped_column(JSON, default=list)  # list[str] bullet points
