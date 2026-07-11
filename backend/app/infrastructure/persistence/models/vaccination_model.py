from datetime import date, datetime
from uuid import UUID

from sqlalchemy import Date, Integer, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.base import Base
from app.infrastructure.persistence.models.sync_mixin import SyncMixin
from app.infrastructure.persistence.models.types import UTCDateTime


class VaccinationModel(Base, SyncMixin):
    __tablename__ = "vaccinations"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    vaccine_name: Mapped[str] = mapped_column(String(100), nullable=False)
    dose_number: Mapped[int] = mapped_column(Integer, nullable=False)
    scheduled_date: Mapped[date] = mapped_column(Date, nullable=False)
    administered_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    hospital_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
