from datetime import datetime, timezone
from uuid import uuid4

from app.application.dto.sleep_dto import SleepResponseDTO, StartSleepDTO
from app.domain.entities.sleep_record import SleepRecord
from app.domain.repositories.sleep_repository import SleepRepository


class StartSleepUseCase:
    def __init__(self, sleep_repo: SleepRepository) -> None:
        self._repo = sleep_repo

    async def execute(self, dto: StartSleepDTO) -> SleepResponseDTO:
        record = SleepRecord(
            id=uuid4(),
            baby_id=dto.baby_id,
            started_at=dto.started_at,
            ended_at=None,
            memo=dto.memo,
            created_at=datetime.now(timezone.utc),
        )
        saved = await self._repo.save(record)
        return SleepResponseDTO(
            id=saved.id,
            baby_id=saved.baby_id,
            started_at=saved.started_at,
            ended_at=saved.ended_at,
            duration_minutes=saved.duration_minutes,
            memo=saved.memo,
            created_at=saved.created_at,
        )
