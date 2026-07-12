from datetime import datetime
from uuid import UUID

from sqlalchemy import String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.base import Base
from app.infrastructure.persistence.models.sync_mixin import SyncMixin
from app.infrastructure.persistence.models.types import UTCDateTime


class DiaperModel(Base, SyncMixin):
    __tablename__ = "diaper_records"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    recorded_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
    diaper_type: Mapped[str] = mapped_column(String(20), nullable=False)
    stool_color: Mapped[str | None] = mapped_column(String(20), nullable=True)
    stool_state: Mapped[str | None] = mapped_column(String(20), nullable=True)
    amount: Mapped[str | None] = mapped_column(String(20), nullable=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
