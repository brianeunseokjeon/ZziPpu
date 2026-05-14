from abc import ABC, abstractmethod
from uuid import UUID

from app.domain.entities.saved_info import SavedInfo


class SavedInfoRepository(ABC):
    @abstractmethod
    async def get(self, id: UUID) -> SavedInfo | None:
        ...

    @abstractmethod
    async def get_by_baby_id(self, baby_id: UUID) -> list[SavedInfo]:
        ...

    @abstractmethod
    async def save(self, info: SavedInfo) -> SavedInfo:
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> None:
        ...
