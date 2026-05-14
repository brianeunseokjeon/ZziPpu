from abc import ABC, abstractmethod
from datetime import date
from uuid import UUID

from app.domain.entities.sleep_record import SleepRecord


class SleepRepository(ABC):
    @abstractmethod
    async def get(self, id: UUID) -> SleepRecord | None:
        ...

    @abstractmethod
    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[SleepRecord]:
        ...

    @abstractmethod
    async def get_active(self, baby_id: UUID) -> SleepRecord | None:
        ...

    @abstractmethod
    async def save(self, record: SleepRecord) -> SleepRecord:
        ...

    @abstractmethod
    async def update(self, record: SleepRecord) -> SleepRecord:
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> None:
        ...
