from app.application.dto.feeding_dto import UpdateFeedingDTO, FeedingResponseDTO
from app.domain.repositories.feeding_repository import FeedingRepository


class UpdateFeedingUseCase:
    def __init__(self, feeding_repo: FeedingRepository) -> None:
        self._repo = feeding_repo

    async def execute(self, dto: UpdateFeedingDTO) -> FeedingResponseDTO:
        feeding = await self._repo.get(dto.id)
        if feeding is None:
            raise ValueError("수유 기록을 찾을 수 없습니다")

        feeding.feeding_type = dto.feeding_type
        feeding.started_at = dto.started_at
        feeding.ended_at = dto.ended_at
        feeding.amount_ml = dto.amount_ml
        feeding.duration_minutes = dto.duration_minutes
        feeding.memo = dto.memo

        updated = await self._repo.update(feeding)
        return FeedingResponseDTO(
            id=updated.id,
            baby_id=updated.baby_id,
            feeding_type=updated.feeding_type,
            started_at=updated.started_at,
            ended_at=updated.ended_at,
            amount_ml=updated.amount_ml,
            duration_minutes=updated.duration_minutes,
            memo=updated.memo,
            created_at=updated.created_at,
        )
