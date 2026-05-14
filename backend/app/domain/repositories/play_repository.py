from abc import ABC, abstractmethod
from datetime import date
from uuid import UUID

from app.domain.entities.play_record import PlayRecord


class PlayRepository(ABC):
    @abstractmethod
    async def get(self, id: UUID) -> PlayRecord | None:
        ...

    @abstractmethod
    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[PlayRecord]:
        ...

    @abstractmethod
    async def save(self, record: PlayRecord) -> PlayRecord:
        ...

    @abstractmethod
    async def update(self, record: PlayRecord) -> PlayRecord:
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> None:
        ...
