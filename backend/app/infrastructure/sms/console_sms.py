import logging

from app.application.interfaces.sms_service import SmsService

logger = logging.getLogger(__name__)


class ConsoleSmsService(SmsService):
    """개발용 — 백엔드 로그에만 출력. 실제 SMS 발송 없음."""

    async def send(self, phone: str, message: str) -> None:
        # uvicorn 기본 로깅에 보이도록 print 사용 (DEV 전용)
        print(f"📨 [DEV SMS] to={phone}  body={message}", flush=True)
