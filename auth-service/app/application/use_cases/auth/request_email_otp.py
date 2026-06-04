import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from app.application.interfaces.email_sender import EmailSender
from app.config import settings
from app.domain.entities.email_otp import EmailOtp
from app.domain.repositories.email_otp_repository import EmailOtpRepository


def hash_otp(code: str) -> str:
    """HMAC-SHA256 with SECRET_KEY as pepper. bcrypt 대신 단순/빠른 해시 (OTP는 5분 TTL, 6자리)."""
    return hmac.new(
        settings.SECRET_KEY.encode("utf-8"),
        code.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


class OtpRateLimitError(Exception):
    """rate-limit 위반. HTTP 429로 매핑."""


def _otp_email_html(code: str) -> str:
    return (
        '<div style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;'
        'max-width:420px;margin:0 auto;padding:24px">'
        '<h2 style="margin:0 0 8px">찌뿌둥 인증번호</h2>'
        '<p style="color:#555;margin:0 0 16px">아래 6자리 인증번호를 5분 안에 입력해 주세요.</p>'
        f'<div style="font-size:32px;font-weight:700;letter-spacing:8px;'
        f'background:#f1f5f9;border-radius:12px;padding:16px;text-align:center">{code}</div>'
        '<p style="color:#999;font-size:12px;margin:16px 0 0">'
        '본인이 요청하지 않았다면 이 메일을 무시하세요.</p>'
        '</div>'
    )


class RequestEmailOtpUseCase:
    def __init__(self, otp_repo: EmailOtpRepository, email_sender: EmailSender) -> None:
        self._repo = otp_repo
        self._email = email_sender

    async def execute(self, email: str, request_ip: str | None) -> None:
        email = email.strip().lower()
        now = datetime.now(timezone.utc)

        # 1. cool-down 검사 (같은 email, 60초 내 재요청 금지)
        latest = await self._repo.get_latest_active(email)
        if latest is not None:
            created_at = latest.created_at
            if created_at.tzinfo is None:
                created_at = created_at.replace(tzinfo=timezone.utc)
            cooldown_end = created_at + timedelta(seconds=settings.OTP_RESEND_COOLDOWN_SECONDS)
            if now < cooldown_end:
                wait = int((cooldown_end - now).total_seconds())
                raise OtpRateLimitError(f"인증번호 재요청은 {wait}초 후에 가능합니다.")

        # 2. 시간당 email-rate 검사
        one_hour_ago = now - timedelta(hours=1)
        email_count = await self._repo.count_since(email, one_hour_ago)
        if email_count >= settings.OTP_MAX_PER_HOUR_PER_EMAIL:
            raise OtpRateLimitError("시간당 요청 한도를 초과했습니다. 1시간 후 다시 시도해주세요.")

        # 3. 시간당 IP-rate 검사
        if request_ip:
            ip_count = await self._repo.count_by_ip_since(request_ip, one_hour_ago)
            if ip_count >= settings.OTP_MAX_PER_HOUR_PER_IP:
                raise OtpRateLimitError("요청이 너무 많습니다. 잠시 후 다시 시도해주세요.")

        # 4. OTP 생성 (6자리 숫자)
        code = "".join(secrets.choice("0123456789") for _ in range(settings.OTP_CODE_LENGTH))
        code_hash = hash_otp(code)

        otp = EmailOtp(
            id=uuid4(),
            email=email,
            code_hash=code_hash,
            expires_at=now + timedelta(seconds=settings.OTP_TTL_SECONDS),
            verified=False,
            attempts=0,
            created_at=now,
            request_ip=request_ip,
        )
        await self._repo.save(otp)

        # 5. 이메일 발송
        if settings.DEV_MODE:
            print(f"\n🔑 [DEV EMAIL OTP] email={email}  code={code}\n", flush=True)
        await self._email.send(email, "[찌뿌둥] 인증번호", _otp_email_html(code))
