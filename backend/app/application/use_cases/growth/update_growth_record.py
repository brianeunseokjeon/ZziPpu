from app.application.dto.growth_dto import GrowthResponseDTO, UpdateGrowthDTO
from app.domain.entities.growth_record import GrowthRecord
from app.domain.repositories.growth_repository import GrowthRepository


class UpdateGrowthRecordUseCase:
    def __init__(self, growth_repo: GrowthRepository) -> None:
        self._repo = growth_repo

    async def execute(self, dto: UpdateGrowthDTO) -> GrowthResponseDTO:
        record = await self._repo.get(dto.record_id)
        # 조회 실패 + 소유권 불일치 모두 404(존재 노출 방지).
        if record is None or record.baby_id != dto.baby_id:
            raise ValueError("성장 기록을 찾을 수 없습니다")

        # 전체 교체(PUT류): 가변 필드를 전달값으로 설정. id/baby_id/created_at은 불변.
        updated = GrowthRecord(
            id=record.id,
            baby_id=record.baby_id,
            # recorded_at은 DB NOT NULL. 미제공 시 기존값 보존.
            recorded_at=dto.recorded_at if dto.recorded_at is not None else record.recorded_at,
            weight_g=dto.weight_g,
            height_cm=dto.height_cm,
            head_circumference_cm=dto.head_circumference_cm,
            memo=dto.memo,
            created_at=record.created_at,
        )
        saved = await self._repo.save(updated)
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
