from functools import lru_cache

from app.application.interfaces.sms_service import SmsService
from app.config import settings
from app.infrastructure.sms.console_sms import ConsoleSmsService
from app.infrastructure.sms.ncp_sens_sms import NcpSensSmsService


@lru_cache(maxsize=1)
def get_sms_service() -> SmsService:
    """settings.SMS_PROVIDER로 구현체 선택. 프로세스 당 1회만 인스턴스화."""
    provider = (settings.SMS_PROVIDER or "console").lower()
    if provider == "ncp_sens":
        return NcpSensSmsService()
    return ConsoleSmsService()
