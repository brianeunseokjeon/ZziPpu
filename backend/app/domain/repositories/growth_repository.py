from abc import ABC, abstractmethod
from uuid import UUID

from app.domain.entities.growth_record import GrowthRecord


class GrowthRepository(ABC):
    @abstractmethod
    async def get(self, id: UUID) -> GrowthRecord | None:
        ...

    @abstractmethod
    async def get_by_baby_id(self, baby_id: UUID) -> list[GrowthRecord]:
        ...

    @abstractmethod
    async def save(self, record: GrowthRecord) -> GrowthRecord:
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> None:
        ...
