from datetime import date
from uuid import UUID

from app.application.dto.play_dto import PlayResponseDTO
from app.domain.repositories.play_repository import PlayRepository


class GetPlayRecordsUseCase:
    def __init__(self, play_repo: PlayRepository) -> None:
        self._repo = play_repo

    async def execute(self, baby_id: UUID, target_date: date) -> list[PlayResponseDTO]:
        records = await self._repo.get_by_baby_and_date(baby_id, target_date)
        return [
            PlayResponseDTO(
                id=r.id,
                baby_id=r.baby_id,
                play_type=r.play_type,
                started_at=r.started_at,
                ended_at=r.ended_at,
                duration_minutes=r.duration_minutes,
                memo=r.memo,
                created_at=r.created_at,
            )
            for r in records
        ]
