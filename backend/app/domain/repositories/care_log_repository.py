from abc import ABC, abstractmethod
from datetime import date
from uuid import UUID

from app.domain.entities.care_log import CareLog


class CareLogRepository(ABC):
    @abstractmethod
    async def get(self, id: UUID) -> CareLog | None:
        ...

    @abstractmethod
    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[CareLog]:
        ...

    @abstractmethod
    async def save(self, record: CareLog) -> CareLog:
        ...

    @abstractmethod
    async def update(self, record: CareLog) -> CareLog:
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> None:
        ...
