from datetime import datetime, timezone
from uuid import uuid4

from app.application.dto.care_log_dto import CareLogResponseDTO, CreateCareLogDTO
from app.domain.entities.care_log import CareLog
from app.domain.repositories.care_log_repository import CareLogRepository


class CreateCareLogUseCase:
    def __init__(self, care_log_repo: CareLogRepository) -> None:
        self._repo = care_log_repo

    async def execute(self, dto: CreateCareLogDTO) -> CareLogResponseDTO:
        record = CareLog(
            id=dto.id or uuid4(),
            baby_id=dto.baby_id,
            category=dto.category,
            name=dto.name,
            dose=dto.dose,
            recorded_at=dto.recorded_at,
            memo=dto.memo,
            created_at=datetime.now(timezone.utc),
        )
        saved = await self._repo.save(record)
        return CareLogResponseDTO(
            id=saved.id,
            baby_id=saved.baby_id,
            category=saved.category,
            name=saved.name,
            dose=saved.dose,
            recorded_at=saved.recorded_at,
            memo=saved.memo,
            created_at=saved.created_at,
        )
