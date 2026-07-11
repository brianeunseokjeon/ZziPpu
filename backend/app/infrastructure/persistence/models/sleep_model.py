from datetime import datetime
from uuid import UUID

from sqlalchemy import Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.base import Base
from app.infrastructure.persistence.models.sync_mixin import SyncMixin
from app.infrastructure.persistence.models.types import UTCDateTime


class SleepModel(Base, SyncMixin):
    __tablename__ = "sleep_records"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    started_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
    ended_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
