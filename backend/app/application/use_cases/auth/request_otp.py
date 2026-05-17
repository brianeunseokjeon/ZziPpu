import hashlib
import hmac
import logging
import secrets
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from app.application.interfaces.sms_service import SmsService
from app.config import settings
from app.domain.entities.otp_code import OtpCode
from app.domain.repositories.otp_repository import OtpRepository

logger = logging.getLogger(__name__)


def hash_otp(code: str) -> str:
    """HMAC-SHA256 with SECRET_KEY as pepper. bcrypt 대신 단순/빠른 해시 (OTP는 5분 TTL, 6자리)."""
    return hmac.new(
        settings.SECRET_KEY.encode("utf-8"),
        code.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


class OtpRateLimitError(Exception):
    """rate-limit 위반. HTTP 429로 매핑."""


class RequestOtpUseCase:
    def __init__(self, otp_repo: OtpRepository, sms_service: SmsService) -> None:
        self._repo = otp_repo
        self._sms = sms_service

    async def execute(self, phone: str, request_ip: str | None) -> None:
        now = datetime.now(timezone.utc)

        # 1. cool-down 검사 (같은 phone, 60초 내 재요청 금지)
        latest = await self._repo.get_latest_active(phone)
        if latest is not None:
            created_at = latest.created_at
            if created_at.tzinfo is None:
                created_at = created_at.replace(tzinfo=timezone.utc)
            cooldown_end = created_at + timedelta(seconds=settings.OTP_COOLDOWN_SECONDS)
            if now < cooldown_end:
                wait = int((cooldown_end - now).total_seconds())
                raise OtpRateLimitError(
                    f"인증번호 재요청은 {wait}초 후에 가능합니다."
                )

        # 2. 시간당 phone-rate 검사
        one_hour_ago = now - timedelta(hours=1)
        phone_count = await self._repo.count_since(phone, one_hour_ago)
        if phone_count >= settings.OTP_HOURLY_PER_PHONE:
            raise OtpRateLimitError("시간당 요청 한도를 초과했습니다. 1시간 후 다시 시도해주세요.")

        # 3. 시간당 IP-rate 검사
        if request_ip:
            ip_count = await self._repo.count_by_ip_since(request_ip, one_hour_ago)
            if ip_count >= settings.OTP_HOURLY_PER_IP:
                raise OtpRateLimitError("요청이 너무 많습니다. 잠시 후 다시 시도해주세요.")

        # 4. OTP 생성 (6자리 숫자)
        code = "".join(secrets.choice("0123456789") for _ in range(settings.OTP_LENGTH))
        code_hash = hash_otp(code)

        otp = OtpCode(
            id=uuid4(),
            phone=phone,
            code_hash=code_hash,
            expires_at=now + timedelta(seconds=settings.OTP_TTL_SECONDS),
            verified=False,
            attempts=0,
            created_at=now,
            request_ip=request_ip,
        )
        await self._repo.save(otp)

        # 5. SMS 발송
        message = f"[먹놀잠] 인증번호: {code} (5분 내 입력)"
        if settings.DEV_MODE:
            # uvicorn 기본 로깅에 보이도록 print 사용 (DEV 전용)
            print(f"\n🔑 [DEV OTP] phone={phone}  code={code}\n", flush=True)
        await self._sms.send(phone, message)
