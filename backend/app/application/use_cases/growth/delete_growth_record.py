from uuid import UUID

from app.domain.repositories.growth_repository import GrowthRepository


class DeleteGrowthRecordUseCase:
    def __init__(self, growth_repo: GrowthRepository) -> None:
        self._repo = growth_repo

    async def execute(self, id: UUID) -> None:
        await self._repo.delete(id)
