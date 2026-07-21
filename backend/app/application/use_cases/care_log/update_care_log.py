from app.application.dto.care_log_dto import CareLogResponseDTO, UpdateCareLogDTO
from app.domain.repositories.care_log_repository import CareLogRepository


class UpdateCareLogUseCase:
    def __init__(self, care_log_repo: CareLogRepository) -> None:
        self._repo = care_log_repo

    async def execute(self, dto: UpdateCareLogDTO) -> CareLogResponseDTO:
        record = await self._repo.get(dto.id)
        if record is None:
            raise ValueError("돌봄 기록을 찾을 수 없습니다")

        record.category = dto.category
        record.name = dto.name
        record.dose = dto.dose
        record.recorded_at = dto.recorded_at
        record.memo = dto.memo

        updated = await self._repo.update(record)
        return CareLogResponseDTO(
            id=updated.id,
            baby_id=updated.baby_id,
            category=updated.category,
            name=updated.name,
            dose=updated.dose,
            recorded_at=updated.recorded_at,
            memo=updated.memo,
            created_at=updated.created_at,
        )
