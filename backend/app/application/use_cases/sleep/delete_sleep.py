from uuid import UUID

from app.domain.repositories.sleep_repository import SleepRepository


class DeleteSleepUseCase:
    def __init__(self, sleep_repo: SleepRepository) -> None:
        self._repo = sleep_repo

    async def execute(self, sleep_id: UUID) -> None:
        await self._repo.delete(sleep_id)
