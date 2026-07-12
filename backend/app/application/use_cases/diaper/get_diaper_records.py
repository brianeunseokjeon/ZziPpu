from datetime import date
from uuid import UUID

from app.application.dto.diaper_dto import DiaperResponseDTO
from app.domain.repositories.diaper_repository import DiaperRepository


class GetDiaperRecordsUseCase:
    def __init__(self, diaper_repo: DiaperRepository) -> None:
        self._repo = diaper_repo

    async def execute(self, baby_id: UUID, target_date: date) -> list[DiaperResponseDTO]:
        records = await self._repo.get_by_baby_and_date(baby_id, target_date)
        return [
            DiaperResponseDTO(
                id=r.id,
                baby_id=r.baby_id,
                recorded_at=r.recorded_at,
                diaper_type=r.diaper_type,
                stool_color=r.stool_color,
                stool_state=r.stool_state,
                amount=r.amount,
                memo=r.memo,
                created_at=r.created_at,
            )
            for r in records
        ]
