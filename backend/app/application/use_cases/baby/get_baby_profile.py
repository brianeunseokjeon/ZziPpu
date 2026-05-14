from uuid import UUID

from app.application.dto.baby_dto import BabyResponseDTO
from app.domain.repositories.baby_repository import BabyRepository


class GetBabyProfileUseCase:
    def __init__(self, baby_repo: BabyRepository) -> None:
        self._repo = baby_repo

    async def execute(self, baby_id: UUID) -> BabyResponseDTO | None:
        baby = await self._repo.get(baby_id)
        if baby is None:
            return None
        return BabyResponseDTO(
            id=baby.id,
            user_id=baby.user_id,
            name=baby.name,
            birth_date=baby.birth_date,
            gender=baby.gender,
            birth_weight_g=baby.birth_weight_g,
            age_days=baby.age_days,
            age_months=baby.age_months,
            created_at=baby.created_at,
        )

    async def get_by_user(self, user_id: UUID) -> list[BabyResponseDTO]:
        babies = await self._repo.get_by_user_id(user_id)
        return [
            BabyResponseDTO(
                id=b.id,
                user_id=b.user_id,
                name=b.name,
                birth_date=b.birth_date,
                gender=b.gender,
                birth_weight_g=b.birth_weight_g,
                age_days=b.age_days,
                age_months=b.age_months,
                created_at=b.created_at,
            )
            for b in babies
        ]
