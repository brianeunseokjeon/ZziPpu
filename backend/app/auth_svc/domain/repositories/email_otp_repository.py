from abc import ABC, abstractmethod
from datetime import datetime
from uuid import UUID

from app.auth_svc.domain.entities.email_otp import EmailOtp


class EmailOtpRepository(ABC):
    @abstractmethod
    async def save(self, otp: EmailOtp) -> EmailOtp: ...

    @abstractmethod
    async def get_latest_active(self, email: str) -> EmailOtp | None: ...

    @abstractmethod
    async def count_since(self, email: str, since: datetime) -> int: ...

    @abstractmethod
    async def count_by_ip_since(self, ip: str, since: datetime) -> int: ...

    @abstractmethod
    async def increment_attempts(self, otp_id: UUID) -> None: ...

    @abstractmethod
    async def mark_verified(self, otp_id: UUID) -> None: ...
