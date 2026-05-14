from datetime import date, datetime
from uuid import UUID

from sqlalchemy import Date, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB

from app.infrastructure.persistence.models.base import Base


class AIReviewModel(Base):
    __tablename__ = "ai_reviews"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), nullable=False, index=True)
    review_date: Mapped[date] = mapped_column(Date, nullable=False)
    feeding_analysis: Mapped[str] = mapped_column(Text, nullable=False)
    sleep_analysis: Mapped[str] = mapped_column(Text, nullable=False)
    diaper_analysis: Mapped[str] = mapped_column(Text, nullable=False)
    play_analysis: Mapped[str] = mapped_column(Text, nullable=False)
    overall_assessment: Mapped[str] = mapped_column(Text, nullable=False)
    alerts: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)
    recommendations: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
