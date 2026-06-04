from uuid import UUID

from app.domain.entities.saved_info import SavedInfo
from app.domain.repositories.saved_info_repository import SavedInfoRepository


class ListSavedInfosUseCase:
    def __init__(self, saved_info_repo: SavedInfoRepository) -> None:
        self._repo = saved_info_repo

    async def execute(self, baby_id: UUID) -> list[SavedInfo]:
        return await self._repo.get_by_baby_id(baby_id)
