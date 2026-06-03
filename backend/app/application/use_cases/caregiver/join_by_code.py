from datetime import datetime, timezone
from uuid import UUID

from app.application.dto.baby_dto import BabyResponseDTO
from app.domain.repositories.baby_repository import BabyRepository
from app.domain.repositories.caregiver_repository import CaregiverRepository


class JoinByCodeUseCase:
    def __init__(
        self,
        baby_repo: BabyRepository,
        caregiver_repo: CaregiverRepository,
    ) -> None:
        self._baby_repo = baby_repo
        self._caregiver_repo = caregiver_repo

    async def execute(self, code: str, user_id: UUID) -> BabyResponseDTO:
        code = code.strip().upper()
        invite = await self._caregiver_repo.get_invite_by_code(code)
        if invite is None:
            raise ValueError("유효하지 않은 초대코드입니다")
        if invite.used_at is not None:
            raise ValueError("이미 사용된 초대코드입니다")
        if invite.expires_at < datetime.now(timezone.utc):
            raise ValueError("만료된 초대코드입니다")

        baby = await self._baby_repo.get(invite.baby_id)
        if baby is None:
            raise ValueError("아기를 찾을 수 없습니다")

        already = baby.user_id == user_id or await self._caregiver_repo.is_member(
            invite.baby_id, user_id
        )
        if not already:
            await self._caregiver_repo.add_member(invite.baby_id, user_id)

        await self._caregiver_repo.mark_invite_used(invite.id, datetime.now(timezone.utc))

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
        )
