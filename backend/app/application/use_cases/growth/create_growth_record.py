from datetime import datetime, timezone
from uuid import uuid4

from app.application.dto.growth_dto import CreateGrowthDTO, GrowthResponseDTO
from app.domain.entities.growth_record import GrowthRecord
from app.domain.repositories.growth_repository import GrowthRepository


class CreateGrowthRecordUseCase:
    def __init__(self, growth_repo: GrowthRepository) -> None:
        self._repo = growth_repo

    async def execute(self, dto: CreateGrowthDTO) -> GrowthResponseDTO:
        record = GrowthRecord(
            id=dto.id or uuid4(),
            baby_id=dto.baby_id,
            recorded_at=dto.recorded_at,
            weight_g=dto.weight_g,
            height_cm=dto.height_cm,
            head_circumference_cm=dto.head_circumference_cm,
            memo=dto.memo,
            created_at=datetime.now(timezone.utc),
        )
        saved = await self._repo.save(record)
        return GrowthResponseDTO(
            id=saved.id,
            baby_id=saved.baby_id,
            recorded_at=saved.recorded_at,
            weight_g=saved.weight_g,
            height_cm=saved.height_cm,
            head_circumference_cm=saved.head_circumference_cm,
            memo=saved.memo,
            created_at=saved.created_at,
        )
