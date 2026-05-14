from uuid import UUID

from app.application.dto.growth_dto import GrowthResponseDTO
from app.domain.repositories.growth_repository import GrowthRepository


class GetGrowthRecordsUseCase:
    def __init__(self, growth_repo: GrowthRepository) -> None:
        self._repo = growth_repo

    async def execute(self, baby_id: UUID) -> list[GrowthResponseDTO]:
        records = await self._repo.get_by_baby_id(baby_id)
        return [
            GrowthResponseDTO(
                id=r.id,
                baby_id=r.baby_id,
                recorded_at=r.recorded_at,
                weight_g=r.weight_g,
                height_cm=r.height_cm,
                head_circumference_cm=r.head_circumference_cm,
                memo=r.memo,
                created_at=r.created_at,
            )
            for r in records
        ]
