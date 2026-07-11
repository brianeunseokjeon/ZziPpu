from datetime import datetime, timezone
from uuid import uuid4

from app.application.dto.play_dto import CreatePlayDTO, PlayResponseDTO
from app.domain.entities.play_record import PlayRecord
from app.domain.repositories.play_repository import PlayRepository


class CreatePlayRecordUseCase:
    def __init__(self, play_repo: PlayRepository) -> None:
        self._repo = play_repo

    async def execute(self, dto: CreatePlayDTO) -> PlayResponseDTO:
        duration = dto.duration_minutes
        if duration is None and dto.ended_at is not None:
            delta = dto.ended_at - dto.started_at
            duration = int(delta.total_seconds() / 60)

        record = PlayRecord(
            id=dto.id or uuid4(),
            baby_id=dto.baby_id,
            play_type=dto.play_type,
            started_at=dto.started_at,
            ended_at=dto.ended_at,
            duration_minutes=duration,
            memo=dto.memo,
            created_at=datetime.now(timezone.utc),
        )
        saved = await self._repo.save(record)
        return PlayResponseDTO(
            id=saved.id,
            baby_id=saved.baby_id,
            play_type=saved.play_type,
            started_at=saved.started_at,
            ended_at=saved.ended_at,
            duration_minutes=saved.duration_minutes,
            memo=saved.memo,
            created_at=saved.created_at,
        )
