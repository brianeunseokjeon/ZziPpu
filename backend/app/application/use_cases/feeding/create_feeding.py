from datetime import datetime, timezone
from uuid import uuid4

from app.application.dto.feeding_dto import CreateFeedingDTO, FeedingResponseDTO
from app.domain.entities.feeding import Feeding
from app.domain.repositories.feeding_repository import FeedingRepository


class CreateFeedingUseCase:
    def __init__(self, feeding_repo: FeedingRepository) -> None:
        self._repo = feeding_repo

    async def execute(self, dto: CreateFeedingDTO) -> FeedingResponseDTO:
        feeding = Feeding(
            id=uuid4(),
            baby_id=dto.baby_id,
            feeding_type=dto.feeding_type,
            started_at=dto.started_at,
            ended_at=dto.ended_at,
            amount_ml=dto.amount_ml,
            duration_minutes=dto.duration_minutes,
            memo=dto.memo,
            created_at=datetime.now(timezone.utc),
        )
        saved = await self._repo.save(feeding)
        return FeedingResponseDTO(
            id=saved.id,
            baby_id=saved.baby_id,
            feeding_type=saved.feeding_type,
            started_at=saved.started_at,
            ended_at=saved.ended_at,
            amount_ml=saved.amount_ml,
            duration_minutes=saved.duration_minutes,
            memo=saved.memo,
            created_at=saved.created_at,
        )
