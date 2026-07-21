from uuid import UUID

from app.domain.repositories.care_log_repository import CareLogRepository


class DeleteCareLogUseCase:
    def __init__(self, care_log_repo: CareLogRepository) -> None:
        self._repo = care_log_repo

    async def execute(self, care_log_id: UUID) -> None:
        await self._repo.delete(care_log_id)
