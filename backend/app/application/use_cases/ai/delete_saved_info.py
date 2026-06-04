from uuid import UUID

from app.domain.repositories.saved_info_repository import SavedInfoRepository


class DeleteSavedInfoUseCase:
    def __init__(self, saved_info_repo: SavedInfoRepository) -> None:
        self._repo = saved_info_repo

    async def execute(self, id: UUID) -> None:
        info = await self._repo.get(id)
        if info is None:
            raise ValueError("Saved info not found")
        await self._repo.delete(id)
