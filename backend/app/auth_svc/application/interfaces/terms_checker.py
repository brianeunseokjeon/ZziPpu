from abc import ABC, abstractmethod
from uuid import UUID


class TermsChecker(ABC):
    """활성 필수 약관 중 미동의가 하나라도 있으면 True. (terms 모듈이 구현)"""

    @abstractmethod
    async def is_agreement_required(self, user_id: UUID) -> bool: ...
