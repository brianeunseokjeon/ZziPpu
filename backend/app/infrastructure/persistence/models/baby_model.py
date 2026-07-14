from datetime import date, datetime
from uuid import UUID

from sqlalchemy import Date, Float, Integer, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.base import Base
from app.infrastructure.persistence.models.sync_mixin import SyncMixin
from app.infrastructure.persistence.models.types import UTCDateTime


class BabyModel(Base, SyncMixin):
    __tablename__ = "babies"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    user_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    birth_date: Mapped[date] = mapped_column(Date, nullable=False)
    gender: Mapped[str | None] = mapped_column(String(20), nullable=True)
    birth_weight_g: Mapped[int | None] = mapped_column(Integer, nullable=True)
    photo_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    # ── 신규(전부 nullable · 하위호환) ────────────────────────────────────────
    birth_height_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    birth_head_circumference_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    birth_chest_circumference_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    blood_type: Mapped[str | None] = mapped_column(String(4), nullable=True)  # A|B|O|AB
    rh_factor: Mapped[str | None] = mapped_column(String(10), nullable=True)  # positive|negative
    birth_time: Mapped[str | None] = mapped_column(String(5), nullable=True)  # "HH:mm" (24h, KST)
    created_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
