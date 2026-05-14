from datetime import date
from uuid import UUID

from app.application.dto.sleep_dto import SleepResponseDTO
from app.domain.repositories.sleep_repository import SleepRepository


class GetSleepRecordsUseCase:
    def __init__(self, sleep_repo: SleepRepository) -> None:
        self._repo = sleep_repo

    async def execute(self, baby_id: UUID, target_date: date) -> list[SleepResponseDTO]:
        records = await self._repo.get_by_baby_and_date(baby_id, target_date)
        return [
            SleepResponseDTO(
                id=r.id,
                baby_id=r.baby_id,
                started_at=r.started_at,
                ended_at=r.ended_at,
                duration_minutes=r.duration_minutes,
                memo=r.memo,
                created_at=r.created_at,
            )
            for r in records
        ]

    async def get_active(self, baby_id: UUID) -> SleepResponseDTO | None:
        record = await self._repo.get_active(baby_id)
        if record is None:
            return None
        return SleepResponseDTO(
            id=record.id,
            baby_id=record.baby_id,
            started_at=record.started_at,
            ended_at=record.ended_at,
            duration_minutes=record.duration_minutes,
            memo=record.memo,
            created_at=record.created_at,
        )
