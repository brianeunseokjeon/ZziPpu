from abc import ABC, abstractmethod
from uuid import UUID


class InvalidInviteCodeError(Exception):
    """core 가 초대코드를 거부함 (미존재/사용됨/만료). HTTP 400 으로 매핑."""


class CaregiverRedeemClient(ABC):
    """core-service 의 내부 리딤 엔드포인트 호출 추상화 (교체 가능)."""

    @abstractmethod
    async def redeem(self, code: str, user_id: UUID) -> UUID:
        """성공 시 baby_id 반환. 코드 무효 시 InvalidInviteCodeError."""
