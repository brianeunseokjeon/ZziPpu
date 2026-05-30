from datetime import date, datetime
from uuid import UUID

from sqlalchemy import Date, JSON, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.base import Base
from app.infrastructure.persistence.models.types import UTCDateTime


class AIReviewModel(Base):
    __tablename__ = "ai_reviews"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    baby_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    review_date: Mapped[date] = mapped_column(Date, nullable=False)
    feeding_analysis: Mapped[str] = mapped_column(Text, nullable=False)
    sleep_analysis: Mapped[str] = mapped_column(Text, nullable=False)
    diaper_analysis: Mapped[str] = mapped_column(Text, nullable=False)
    play_analysis: Mapped[str] = mapped_column(Text, nullable=False)
    overall_assessment: Mapped[str] = mapped_column(Text, nullable=False)
    alerts: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    recommendations: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    positives: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    considerations: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    concerns: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    critical_warnings: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    created_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
