from datetime import datetime
from uuid import UUID

from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth_svc.domain.entities.email_otp import EmailOtp
from app.auth_svc.domain.repositories.email_otp_repository import EmailOtpRepository
from app.auth_svc.infrastructure.persistence.models.email_otp_model import EmailOtpModel


class EmailOtpRepositoryImpl(EmailOtpRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: EmailOtpModel) -> EmailOtp:
        return EmailOtp(
            id=model.id,
            email=model.email,
            code_hash=model.code_hash,
            expires_at=model.expires_at,
            verified=model.verified,
            attempts=model.attempts,
            created_at=model.created_at,
            request_ip=model.request_ip,
        )

    async def save(self, otp: EmailOtp) -> EmailOtp:
        model = EmailOtpModel(
            id=otp.id,
            email=otp.email,
            code_hash=otp.code_hash,
            expires_at=otp.expires_at,
            verified=otp.verified,
            attempts=otp.attempts,
            created_at=otp.created_at,
            request_ip=otp.request_ip,
        )
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def get_latest_active(self, email: str) -> EmailOtp | None:
        """미사용인 가장 최신 OTP. 만료 여부는 use case가 판단."""
        stmt = (
            select(EmailOtpModel)
            .where(EmailOtpModel.email == email, EmailOtpModel.verified.is_(False))
            .order_by(desc(EmailOtpModel.created_at))
            .limit(1)
        )
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def count_since(self, email: str, since: datetime) -> int:
        stmt = select(func.count(EmailOtpModel.id)).where(
            EmailOtpModel.email == email,
            EmailOtpModel.created_at >= since,
        )
        result = await self._session.execute(stmt)
        return int(result.scalar_one() or 0)

    async def count_by_ip_since(self, ip: str, since: datetime) -> int:
        stmt = select(func.count(EmailOtpModel.id)).where(
            EmailOtpModel.request_ip == ip,
            EmailOtpModel.created_at >= since,
        )
        result = await self._session.execute(stmt)
        return int(result.scalar_one() or 0)

    async def increment_attempts(self, otp_id: UUID) -> None:
        model = await self._session.get(EmailOtpModel, otp_id)
        if model is None:
            return
        model.attempts += 1
        await self._session.flush()

    async def mark_verified(self, otp_id: UUID) -> None:
        model = await self._session.get(EmailOtpModel, otp_id)
        if model is None:
            return
        model.verified = True
        await self._session.flush()
