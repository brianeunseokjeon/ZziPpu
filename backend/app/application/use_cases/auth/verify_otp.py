import hmac
from dataclasses import dataclass
from datetime import date, datetime, timezone
from uuid import UUID, uuid4

from app.application.use_cases.auth.request_otp import hash_otp
from app.config import settings
from app.domain.entities.baby import Baby
from app.domain.entities.user import User
from app.domain.repositories.baby_repository import BabyRepository
from app.domain.repositories.otp_repository import OtpRepository
from app.domain.repositories.user_repository import UserRepository
from app.infrastructure.auth.jwt_handler import create_access_token


class OtpInvalidError(Exception):
    """OTP가 유효하지 않음 (만료/없음/시도 초과)."""


class OtpCodeMismatchError(Exception):
    """code가 일치하지 않음."""


@dataclass
class VerifyOtpResult:
    access_token: str
    user_id: UUID
    baby_id: UUID
    is_new_user: bool


class VerifyOtpUseCase:
    def __init__(
        self,
        otp_repo: OtpRepository,
        user_repo: UserRepository,
        baby_repo: BabyRepository,
    ) -> None:
        self._otp_repo = otp_repo
        self._user_repo = user_repo
        self._baby_repo = baby_repo

    async def execute(self, phone: str, code: str) -> VerifyOtpResult:
        now = datetime.now(timezone.utc)
        otp = await self._otp_repo.get_latest_active(phone)
        expires_at = (
            otp.expires_at.replace(tzinfo=timezone.utc)
            if otp and otp.expires_at.tzinfo is None
            else (otp.expires_at if otp else None)
        )

        if otp is None or otp.verified or (expires_at is not None and expires_at < now):
            raise OtpInvalidError("인증번호가 만료되었거나 존재하지 않습니다. 다시 요청해주세요.")

        if otp.attempts >= settings.OTP_MAX_ATTEMPTS:
            raise OtpInvalidError("인증 시도 횟수를 초과했습니다. 다시 요청해주세요.")

        if not hmac.compare_digest(hash_otp(code), otp.code_hash):
            await self._otp_repo.increment_attempts(otp.id)
            remaining = settings.OTP_MAX_ATTEMPTS - (otp.attempts + 1)
            raise OtpCodeMismatchError(
                f"인증번호가 일치하지 않습니다. (남은 시도: {max(remaining, 0)}회)"
            )

        # OTP 검증 성공
        await self._otp_repo.mark_verified(otp.id)

        # user 조회 / 신규 생성
        user = await self._user_repo.get_by_phone(phone)
        is_new_user = user is None

        if user is None:
            new_user_id = uuid4()
            user = User(
                id=new_user_id,
                # SQLite는 email NOT NULL이라 synthetic 값 부여. PostgreSQL 전환 시 nullable로 마이그레이션.
                email=f"otp+{new_user_id}@phone.local",
                name=None,
                created_at=now,
                phone=phone,
            )
            user = await self._user_repo.save(user)

            # baby도 자동 생성 (birth_date는 onboarding에서 입력하므로 임시값)
            baby = Baby(
                id=uuid4(),
                user_id=user.id,
                name="우리 아기",
                birth_date=date.today(),  # 임시. onboarding에서 수정
                gender=None,
                birth_weight_g=None,
                created_at=now,
            )
            saved_baby = await self._baby_repo.save(baby)
            baby_id = saved_baby.id
        else:
            babies = await self._baby_repo.get_by_user_id(user.id)
            if babies:
                baby_id = babies[0].id
            else:
                # user는 있는데 baby가 없는 경우 (이전 가입 후 미완료)
                baby = Baby(
                    id=uuid4(),
                    user_id=user.id,
                    name="우리 아기",
                    birth_date=date.today(),
                    gender=None,
                    birth_weight_g=None,
                    created_at=now,
                )
                saved_baby = await self._baby_repo.save(baby)
                baby_id = saved_baby.id
                is_new_user = True  # 사실상 신규 흐름

        token = create_access_token(user.id)
        return VerifyOtpResult(
            access_token=token,
            user_id=user.id,
            baby_id=baby_id,
            is_new_user=is_new_user,
        )
