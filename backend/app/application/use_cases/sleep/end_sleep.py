from app.application.dto.sleep_dto import EndSleepDTO, SleepResponseDTO
from app.domain.repositories.sleep_repository import SleepRepository


class EndSleepUseCase:
    def __init__(self, sleep_repo: SleepRepository) -> None:
        self._repo = sleep_repo

    async def execute(self, dto: EndSleepDTO) -> SleepResponseDTO:
        record = await self._repo.get(dto.sleep_id)
        if record is None:
            raise ValueError(f"Sleep record {dto.sleep_id} not found")
        record.ended_at = dto.ended_at
        updated = await self._repo.update(record)
        return SleepResponseDTO(
            id=updated.id,
            baby_id=updated.baby_id,
            started_at=updated.started_at,
            ended_at=updated.ended_at,
            duration_minutes=updated.duration_minutes,
            memo=updated.memo,
            created_at=updated.created_at,
        )
