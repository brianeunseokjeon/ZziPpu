from dataclasses import dataclass
from datetime import datetime, timezone
from uuid import UUID, uuid4

from app.auth_svc.application.interfaces.caregiver_redeem_client import (
    CaregiverRedeemClient,
    InvalidInviteCodeError,
)
from app.auth_svc.application.interfaces.terms_checker import TermsChecker
from app.auth_svc.domain.entities.user import User
from app.auth_svc.domain.repositories.user_repository import UserRepository
from app.auth_svc.infrastructure.auth.jwt_handler import create_access_token


@dataclass
class RedeemInviteCodeResult:
    access_token: str
    user_id: UUID
    baby_id: UUID
    is_new_user: bool
    terms_required: bool


class RedeemInviteCodeUseCase:
    """이메일 없이 초대코드만으로 공동양육자 로그인.

    1. 이메일 없는 공동양육자 user 생성
    2. core 내부 API 로 코드 리딤 (baby_caregivers 링크 + 코드 소비)
    3. 코드 무효 시 방금 만든 user 를 폐기하고 에러 전파
    4. 성공 시 JWT 발급
    """

    def __init__(
        self,
        user_repo: UserRepository,
        redeem_client: CaregiverRedeemClient,
        terms_checker: TermsChecker,
    ) -> None:
        self._user_repo = user_repo
        self._redeem_client = redeem_client
        self._terms_checker = terms_checker

    async def execute(self, code: str) -> RedeemInviteCodeResult:
        now = datetime.now(timezone.utc)
        user = await self._user_repo.save(
            User(
                id=uuid4(),
                email=None,
                name=None,
                is_caregiver=True,
                created_at=now,
            )
        )

        try:
            baby_id = await self._redeem_client.redeem(code.strip(), user.id)
        except InvalidInviteCodeError:
            # 코드 무효 → 방금 만든 공동양육자 user 폐기
            await self._user_repo.delete(user.id)
            raise

        terms_required = await self._terms_checker.is_agreement_required(user.id)
        token = create_access_token(user.id)
        return RedeemInviteCodeResult(
            access_token=token,
            user_id=user.id,
            baby_id=baby_id,
            is_new_user=True,
            terms_required=terms_required,
        )
