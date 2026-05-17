from abc import ABC, abstractmethod
from datetime import datetime
from uuid import UUID

from app.domain.entities.otp_code import OtpCode


class OtpRepository(ABC):
    @abstractmethod
    async def save(self, otp: OtpCode) -> OtpCode:
        ...

    @abstractmethod
    async def get_latest_active(self, phone: str) -> OtpCode | None:
        """미사용/미만료인 가장 최신 OTP. rate-limit / verify에 사용."""
        ...

    @abstractmethod
    async def count_since(self, phone: str, since: datetime) -> int:
        """phone당 시간당 요청 수 (rate-limit용)."""
        ...

    @abstractmethod
    async def count_by_ip_since(self, ip: str, since: datetime) -> int:
        ...

    @abstractmethod
    async def increment_attempts(self, id: UUID) -> None:
        ...

    @abstractmethod
    async def mark_verified(self, id: UUID) -> None:
        ...
