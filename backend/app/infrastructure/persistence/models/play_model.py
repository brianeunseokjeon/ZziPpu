from datetime import datetime
from uuid import UUID

from sqlalchemy import Integer, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.base import Base
from app.infrastructure.persistence.models.types import UTCDateTime


class PlayModel(Base):
    __tablename__ = "play_records"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    play_type: Mapped[str] = mapped_column(String(50), nullable=False)
    started_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
    ended_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)
    duration_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
