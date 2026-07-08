from datetime import date, datetime
from uuid import UUID

from sqlalchemy import Boolean, Date, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.auth_svc.infrastructure.persistence.models.base import Base
from app.auth_svc.infrastructure.persistence.models.types import UTCDateTime


class TermModel(Base):
    __tablename__ = "terms"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    type: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    version: Mapped[str] = mapped_column(String(20), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[str] = mapped_column(String, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, index=True)
    required: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    effective_date: Mapped[date] = mapped_column(Date, nullable=False)


class TermsAgreementModel(Base):
    __tablename__ = "terms_agreements"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    user_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    term_type: Mapped[str] = mapped_column(String(20), nullable=False)
    term_version: Mapped[str] = mapped_column(String(20), nullable=False)
    agreed_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
