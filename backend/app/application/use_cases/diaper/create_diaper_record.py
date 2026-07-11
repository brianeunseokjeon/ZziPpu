from datetime import datetime, timezone
from uuid import uuid4

from app.application.dto.diaper_dto import CreateDiaperDTO, DiaperResponseDTO
from app.domain.entities.diaper import DiaperRecord
from app.domain.repositories.diaper_repository import DiaperRepository


class CreateDiaperRecordUseCase:
    def __init__(self, diaper_repo: DiaperRepository) -> None:
        self._repo = diaper_repo

    async def execute(self, dto: CreateDiaperDTO) -> DiaperResponseDTO:
        record = DiaperRecord(
            id=dto.id or uuid4(),
            baby_id=dto.baby_id,
            recorded_at=dto.recorded_at,
            diaper_type=dto.diaper_type,
            stool_color=dto.stool_color,
            stool_state=dto.stool_state,
            memo=dto.memo,
            created_at=datetime.now(timezone.utc),
        )
        saved = await self._repo.save(record)
        return DiaperResponseDTO(
            id=saved.id,
            baby_id=saved.baby_id,
            recorded_at=saved.recorded_at,
            diaper_type=saved.diaper_type,
            stool_color=saved.stool_color,
            stool_state=saved.stool_state,
            memo=saved.memo,
            created_at=saved.created_at,
        )
