from datetime import date, datetime
from uuid import UUID

from sqlalchemy import Date, DateTime, Float, Integer, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.base import Base


class GrowthModel(Base):
    __tablename__ = "growth_records"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    recorded_at: Mapped[date] = mapped_column(Date, nullable=False)
    weight_g: Mapped[int | None] = mapped_column(Integer, nullable=True)
    height_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    head_circumference_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
