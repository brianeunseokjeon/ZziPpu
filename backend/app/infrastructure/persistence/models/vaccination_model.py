from datetime import date, datetime
from uuid import UUID

from sqlalchemy import Date, DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID as PGUUID

from app.infrastructure.persistence.models.base import Base


class VaccinationModel(Base):
    __tablename__ = "vaccinations"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), nullable=False, index=True)
    vaccine_name: Mapped[str] = mapped_column(String(100), nullable=False)
    dose_number: Mapped[int] = mapped_column(Integer, nullable=False)
    scheduled_date: Mapped[date] = mapped_column(Date, nullable=False)
    administered_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    hospital_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
