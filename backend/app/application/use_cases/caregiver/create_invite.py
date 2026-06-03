import secrets
from datetime import datetime, timedelta, timezone
from uuid import UUID

from app.domain.entities.caregiver import CaregiverInvite
from app.domain.repositories.baby_repository import BabyRepository
from app.domain.repositories.caregiver_repository import CaregiverRepository

# 헷갈리는 문자(0/O, 1/I/L) 제외한 코드 알파벳
_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
_CODE_LEN = 6
_TTL_HOURS = 24


def _generate_code() -> str:
    return "".join(secrets.choice(_ALPHABET) for _ in range(_CODE_LEN))


class CreateInviteUseCase:
    def __init__(
        self,
        baby_repo: BabyRepository,
        caregiver_repo: CaregiverRepository,
    ) -> None:
        self._baby_repo = baby_repo
        self._caregiver_repo = caregiver_repo

    async def execute(self, baby_id: UUID, user_id: UUID) -> CaregiverInvite:
        baby = await self._baby_repo.get(baby_id)
        if baby is None:
            raise ValueError("아기를 찾을 수 없습니다")

        is_owner = baby.user_id == user_id
        if not is_owner and not await self._caregiver_repo.is_member(baby_id, user_id):
            raise PermissionError("이 아기의 양육자만 초대할 수 있습니다")

        # 고유 코드 보장 (충돌 시 재시도)
        code = _generate_code()
        for _ in range(5):
            if await self._caregiver_repo.get_invite_by_code(code) is None:
                break
            code = _generate_code()

        expires_at = datetime.now(timezone.utc) + timedelta(hours=_TTL_HOURS)
        return await self._caregiver_repo.create_invite(
            baby_id=baby_id, created_by=user_id, code=code, expires_at=expires_at
        )
