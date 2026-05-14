from uuid import UUID

from app.domain.repositories.feeding_repository import FeedingRepository


class DeleteFeedingUseCase:
    def __init__(self, feeding_repo: FeedingRepository) -> None:
        self._repo = feeding_repo

    async def execute(self, feeding_id: UUID) -> None:
        await self._repo.delete(feeding_id)
