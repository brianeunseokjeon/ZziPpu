from uuid import UUID

from app.application.dto.baby_dto import BabyResponseDTO
from app.domain.repositories.baby_repository import BabyRepository
from app.domain.repositories.caregiver_repository import CaregiverRepository


def _to_dto(baby) -> BabyResponseDTO:
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
        photo_url=baby.photo_url,
        birth_height_cm=baby.birth_height_cm,
        birth_head_circumference_cm=baby.birth_head_circumference_cm,
        birth_chest_circumference_cm=baby.birth_chest_circumference_cm,
        blood_type=baby.blood_type,
        rh_factor=baby.rh_factor,
        birth_time=baby.birth_time,
    )


class GetBabyProfileUseCase:
    def __init__(
        self,
        baby_repo: BabyRepository,
        caregiver_repo: CaregiverRepository | None = None,
    ) -> None:
        self._repo = baby_repo
        self._caregiver_repo = caregiver_repo

    async def execute(self, baby_id: UUID) -> BabyResponseDTO | None:
        baby = await self._repo.get(baby_id)
        if baby is None:
            return None
        return _to_dto(baby)

    async def get_by_user(self, user_id: UUID) -> list[BabyResponseDTO]:
        babies = await self._repo.get_by_user_id(user_id)
        seen = {b.id for b in babies}

        # 공동 양육자로 참여한 아기도 포함
        if self._caregiver_repo is not None:
            shared_ids = await self._caregiver_repo.get_baby_ids_for_user(user_id)
            for baby_id in shared_ids:
                if baby_id in seen:
                    continue
                shared = await self._repo.get(baby_id)
                if shared is not None:
                    babies.append(shared)
                    seen.add(baby_id)

        return [_to_dto(b) for b in babies]
