from datetime import date
from uuid import UUID

from app.application.dto.feeding_dto import FeedingResponseDTO
from app.domain.repositories.feeding_repository import FeedingRepository


class GetFeedingsUseCase:
    def __init__(self, feeding_repo: FeedingRepository) -> None:
        self._repo = feeding_repo

    async def execute(self, baby_id: UUID, target_date: date) -> list[FeedingResponseDTO]:
        feedings = await self._repo.get_by_baby_and_date(baby_id, target_date)
        return [
            FeedingResponseDTO(
                id=f.id,
                baby_id=f.baby_id,
                feeding_type=f.feeding_type,
                started_at=f.started_at,
                ended_at=f.ended_at,
                amount_ml=f.amount_ml,
                duration_minutes=f.duration_minutes,
                memo=f.memo,
                did_vomit=f.did_vomit,
                created_at=f.created_at,
            )
            for f in feedings
        ]
