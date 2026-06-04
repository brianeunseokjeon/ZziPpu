from datetime import datetime, timezone
from uuid import uuid4

from app.application.dto.baby_dto import BabyResponseDTO, CreateBabyDTO
from app.domain.entities.baby import Baby
from app.domain.repositories.baby_repository import BabyRepository


class RegisterBabyUseCase:
    def __init__(self, baby_repo: BabyRepository) -> None:
        self._repo = baby_repo

    async def execute(self, dto: CreateBabyDTO) -> BabyResponseDTO:
        baby = Baby(
            id=uuid4(),
            user_id=dto.user_id,
            name=dto.name,
            birth_date=dto.birth_date,
            gender=dto.gender,
            birth_weight_g=dto.birth_weight_g,
            created_at=datetime.now(timezone.utc),
        )
        saved = await self._repo.save(baby)
        return BabyResponseDTO(
            id=saved.id,
            user_id=saved.user_id,
            name=saved.name,
            birth_date=saved.birth_date,
            gender=saved.gender,
            birth_weight_g=saved.birth_weight_g,
            age_days=saved.age_days,
            age_months=saved.age_months,
            created_at=saved.created_at,
        )
