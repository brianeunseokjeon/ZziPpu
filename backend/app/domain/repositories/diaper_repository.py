from abc import ABC, abstractmethod
from datetime import date
from uuid import UUID

from app.domain.entities.diaper import DiaperRecord


class DiaperRepository(ABC):
    @abstractmethod
    async def get(self, id: UUID) -> DiaperRecord | None:
        ...

    @abstractmethod
    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[DiaperRecord]:
        ...

    @abstractmethod
    async def save(self, record: DiaperRecord) -> DiaperRecord:
        ...

    @abstractmethod
    async def update(self, record: DiaperRecord) -> DiaperRecord:
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> None:
        ...
