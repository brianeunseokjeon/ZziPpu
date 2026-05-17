from datetime import datetime
from uuid import UUID

from sqlalchemy import String, DateTime, Integer, Boolean, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.base import Base


class OtpModel(Base):
    __tablename__ = "otp_codes"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    phone: Mapped[str] = mapped_column(String(32), nullable=False, index=True)
    code_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    verified: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    attempts: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    request_ip: Mapped[str | None] = mapped_column(String(64), nullable=True)
