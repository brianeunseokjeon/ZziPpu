import hmac
from dataclasses import dataclass
from datetime import datetime, timezone
from uuid import UUID, uuid4

from app.auth_svc.application.interfaces.terms_checker import TermsChecker
from app.auth_svc.application.use_cases.auth.request_email_otp import hash_otp
from app.auth_svc.config import settings
from app.auth_svc.domain.entities.user import User
from app.auth_svc.domain.repositories.email_otp_repository import EmailOtpRepository
from app.auth_svc.domain.repositories.user_repository import UserRepository
from app.auth_svc.infrastructure.auth.jwt_handler import create_access_token


class OtpInvalidError(Exception):
    """OTP가 유효하지 않음 (만료/없음/시도 초과)."""


class OtpCodeMismatchError(Exception):
    """code가 일치하지 않음."""


@dataclass
class VerifyEmailOtpResult:
    access_token: str
    user_id: UUID
    is_new_user: bool
    terms_required: bool


class VerifyEmailOtpUseCase:
    def __init__(
        self,
        otp_repo: EmailOtpRepository,
        user_repo: UserRepository,
        terms_checker: TermsChecker,
    ) -> None:
        self._otp_repo = otp_repo
        self._user_repo = user_repo
        self._terms_checker = terms_checker

    async def execute(self, email: str, code: str) -> VerifyEmailOtpResult:
        email = email.strip().lower()
        now = datetime.now(timezone.utc)
        otp = await self._otp_repo.get_latest_active(email)
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

        # user 조회 / 신규 생성 (baby는 생성하지 않음 — 온보딩에서 POST /babies)
        user = await self._user_repo.get_by_email(email)
        is_new_user = user is None
        if user is None:
            user = await self._user_repo.save(
                User(
                    id=uuid4(),
                    email=email,
                    name=None,
                    is_caregiver=False,
                    created_at=now,
                )
            )

        terms_required = await self._terms_checker.is_agreement_required(user.id)
        token = create_access_token(user.id)
        return VerifyEmailOtpResult(
            access_token=token,
            user_id=user.id,
            is_new_user=is_new_user,
            terms_required=terms_required,
        )
