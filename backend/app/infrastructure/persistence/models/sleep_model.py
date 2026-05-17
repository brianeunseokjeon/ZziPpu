from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.base import Base


class SleepModel(Base):
    __tablename__ = "sleep_records"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
