from datetime import date
from uuid import UUID

from app.application.dto.care_log_dto import CareLogResponseDTO
from app.domain.repositories.care_log_repository import CareLogRepository


class GetCareLogsUseCase:
    def __init__(self, care_log_repo: CareLogRepository) -> None:
        self._repo = care_log_repo

    async def execute(self, baby_id: UUID, target_date: date) -> list[CareLogResponseDTO]:
        records = await self._repo.get_by_baby_and_date(baby_id, target_date)
        return [
            CareLogResponseDTO(
                id=r.id,
                baby_id=r.baby_id,
                category=r.category,
                name=r.name,
                dose=r.dose,
                recorded_at=r.recorded_at,
                memo=r.memo,
                created_at=r.created_at,
            )
            for r in records
        ]
