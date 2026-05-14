from abc import ABC, abstractmethod
from datetime import date
from uuid import UUID

from app.domain.entities.baby import Baby


class BabyRepository(ABC):
    @abstractmethod
    async def get(self, id: UUID) -> Baby | None:
        ...

    @abstractmethod
    async def get_by_user_id(self, user_id: UUID) -> list[Baby]:
        ...

    @abstractmethod
    async def save(self, baby: Baby) -> Baby:
        ...

    @abstractmethod
    async def update(self, baby: Baby) -> Baby:
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> None:
        ...
