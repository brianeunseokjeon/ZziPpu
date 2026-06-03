from abc import ABC, abstractmethod
from uuid import UUID

from app.domain.entities.caregiver import Caregiver, CaregiverInvite


class CaregiverRepository(ABC):
    @abstractmethod
    async def add_member(self, baby_id: UUID, user_id: UUID, role: str = "caregiver") -> Caregiver:
        ...

    @abstractmethod
    async def get_baby_ids_for_user(self, user_id: UUID) -> list[UUID]:
        ...

    @abstractmethod
    async def is_member(self, baby_id: UUID, user_id: UUID) -> bool:
        ...

    @abstractmethod
    async def list_members(self, baby_id: UUID) -> list[Caregiver]:
        ...

    @abstractmethod
    async def create_invite(self, baby_id: UUID, created_by: UUID, code: str, expires_at) -> CaregiverInvite:
        ...

    @abstractmethod
    async def get_invite_by_code(self, code: str) -> CaregiverInvite | None:
        ...

    @abstractmethod
    async def mark_invite_used(self, invite_id: UUID, used_at) -> None:
        ...
