from datetime import datetime
from uuid import UUID

from sqlalchemy import Boolean, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.auth_svc.infrastructure.persistence.models.base import Base
from app.auth_svc.infrastructure.persistence.models.types import UTCDateTime


class UserModel(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True, index=True)
    name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    is_caregiver: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
    # 회원 탈퇴(소프트삭제) 시각. 설정되면 유예상태, 재로그인 시 해제(복구),
    # 30일 경과분은 기동 시 완전삭제(계정+전 기록). None이면 정상 계정.
    deleted_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)
