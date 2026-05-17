from uuid import UUID

from app.domain.repositories.diaper_repository import DiaperRepository


class DeleteDiaperUseCase:
    def __init__(self, diaper_repo: DiaperRepository) -> None:
        self._repo = diaper_repo

    async def execute(self, diaper_id: UUID) -> None:
        await self._repo.delete(diaper_id)
