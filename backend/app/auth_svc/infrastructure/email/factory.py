from functools import lru_cache

from app.auth_svc.application.interfaces.email_sender import EmailSender
from app.auth_svc.config import settings
from app.auth_svc.infrastructure.email.console_email import ConsoleEmailSender
from app.auth_svc.infrastructure.email.resend_email import ResendEmailSender


@lru_cache
def get_email_sender() -> EmailSender:
    """EMAIL_PROVIDER env 로 구현을 선택한다. 새 provider 는 여기에만 추가하면 된다."""
    provider = (settings.EMAIL_PROVIDER or "console").lower()
    if provider == "resend":
        if not settings.RESEND_API_KEY:
            raise RuntimeError("EMAIL_PROVIDER=resend 이지만 RESEND_API_KEY 가 비어 있습니다.")
        return ResendEmailSender(api_key=settings.RESEND_API_KEY, sender=settings.EMAIL_FROM)
    return ConsoleEmailSender()
