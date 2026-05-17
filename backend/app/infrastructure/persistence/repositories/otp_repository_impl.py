from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.otp_code import OtpCode
from app.domain.repositories.otp_repository import OtpRepository
from app.infrastructure.persistence.models.otp_model import OtpModel


class OtpRepositoryImpl(OtpRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: OtpModel) -> OtpCode:
        return OtpCode(
            id=model.id,
            phone=model.phone,
            code_hash=model.code_hash,
            expires_at=model.expires_at,
            verified=model.verified,
            attempts=model.attempts,
            created_at=model.created_at,
            request_ip=model.request_ip,
        )

    async def save(self, otp: OtpCode) -> OtpCode:
        model = OtpModel(
            id=otp.id,
            phone=otp.phone,
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

    async def get_latest_active(self, phone: str) -> OtpCode | None:
        """미사용인 가장 최신 OTP. 만료 여부는 use case가 판단."""
        stmt = (
            select(OtpModel)
            .where(OtpModel.phone == phone, OtpModel.verified.is_(False))
            .order_by(desc(OtpModel.created_at))
            .limit(1)
        )
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def count_since(self, phone: str, since: datetime) -> int:
        stmt = select(func.count(OtpModel.id)).where(
            OtpModel.phone == phone,
            OtpModel.created_at >= since,
        )
        result = await self._session.execute(stmt)
        return int(result.scalar_one() or 0)

    async def count_by_ip_since(self, ip: str, since: datetime) -> int:
        stmt = select(func.count(OtpModel.id)).where(
            OtpModel.request_ip == ip,
            OtpModel.created_at >= since,
        )
        result = await self._session.execute(stmt)
        return int(result.scalar_one() or 0)

    async def increment_attempts(self, id: UUID) -> None:
        model = await self._session.get(OtpModel, id)
        if model is None:
            return
        model.attempts += 1
        await self._session.flush()

    async def mark_verified(self, id: UUID) -> None:
        model = await self._session.get(OtpModel, id)
        if model is None:
            return
        model.verified = True
        await self._session.flush()
