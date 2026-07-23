from abc import ABC, abstractmethod
from datetime import datetime
from uuid import UUID

from app.auth_svc.domain.entities.user import User


class UserRepository(ABC):
    @abstractmethod
    async def get(self, user_id: UUID) -> User | None: ...

    @abstractmethod
    async def get_by_email(self, email: str) -> User | None: ...

    @abstractmethod
    async def save(self, user: User) -> User: ...

    @abstractmethod
    async def delete(self, user_id: UUID) -> None: ...

    @abstractmethod
    async def soft_delete(self, user_id: UUID, when: datetime) -> None:
        """탈퇴(소프트삭제): deleted_at 설정."""

    @abstractmethod
    async def restore(self, user_id: UUID) -> None:
        """탈퇴 취소: deleted_at 해제."""

    @abstractmethod
    async def list_purgeable_ids(self, before: datetime) -> list[UUID]:
        """deleted_at 이 before 이전인(유예 만료) 유저 id 목록 — 완전삭제 대상."""
