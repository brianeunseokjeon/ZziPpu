import logging

import httpx

from app.auth_svc.application.interfaces.email_sender import EmailSender

logger = logging.getLogger(__name__)

_RESEND_ENDPOINT = "https://api.resend.com/emails"


class ResendEmailSender(EmailSender):
    """Resend (https://resend.com) API 기반 발송. 도메인 인증 후 EMAIL_FROM 사용."""

    def __init__(self, api_key: str, sender: str) -> None:
        self._api_key = api_key
        self._sender = sender

    async def send(self, to: str, subject: str, html: str) -> None:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                _RESEND_ENDPOINT,
                headers={
                    "Authorization": f"Bearer {self._api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "from": self._sender,
                    "to": [to],
                    "subject": subject,
                    "html": html,
                },
            )
            if resp.is_error:
                # 도메인 미인증 / 키 오류 / 발신주소 불일치 등 진단용 본문 출력
                logger.error(
                    "Resend 발송 실패 (status=%s): %s", resp.status_code, resp.text
                )
                print(
                    f"❌ [RESEND ERROR] status={resp.status_code} body={resp.text}"
                )
            resp.raise_for_status()
