from datetime import datetime
from uuid import UUID

from sqlalchemy import String, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID as PGUUID

from app.infrastructure.persistence.models.base import Base


class DiaperModel(Base):
    __tablename__ = "diaper_records"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), nullable=False, index=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    diaper_type: Mapped[str] = mapped_column(String(20), nullable=False)
    stool_color: Mapped[str | None] = mapped_column(String(20), nullable=True)
    stool_state: Mapped[str | None] = mapped_column(String(20), nullable=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
