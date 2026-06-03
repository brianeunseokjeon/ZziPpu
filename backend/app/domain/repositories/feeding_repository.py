from abc import ABC, abstractmethod
from datetime import date
from uuid import UUID

from app.domain.entities.feeding import Feeding


class FeedingRepository(ABC):
    @abstractmethod
    async def get(self, id: UUID) -> Feeding | None:
        ...

    @abstractmethod
    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[Feeding]:
        ...

    @abstractmethod
    async def get_recent(self, baby_id: UUID, limit: int = 12) -> list[Feeding]:
        ...

    @abstractmethod
    async def save(self, feeding: Feeding) -> Feeding:
        ...

    @abstractmethod
    async def update(self, feeding: Feeding) -> Feeding:
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> None:
        ...
