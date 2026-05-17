import base64
import hashlib
import hmac
import logging
import time

import httpx

from app.application.interfaces.sms_service import SmsService
from app.config import settings

logger = logging.getLogger(__name__)

NCP_SENS_BASE = "https://sens.apigw.ntruss.com"


def _e164_to_kr_local(phone: str) -> str:
    """E.164(+821012345678) → NCP가 받는 01012345678 형태."""
    if phone.startswith("+82"):
        return "0" + phone[3:]
    return phone


def _make_signature(method: str, url_path: str, timestamp: str) -> str:
    """NCP API signature v2 생성."""
    message = f"{method} {url_path}\n{timestamp}\n{settings.SMS_API_KEY}"
    secret = (settings.SMS_API_SECRET or "").encode("utf-8")
    sig = hmac.new(secret, message.encode("utf-8"), hashlib.sha256).digest()
    return base64.b64encode(sig).decode("utf-8")


class NcpSensSmsService(SmsService):
    """운영용 — Naver Cloud Platform Sens SMS API.

    env:
      SMS_API_KEY        : NCP access key id
      SMS_API_SECRET     : NCP secret key
      SMS_SERVICE_ID     : Sens 서비스 id (콘솔에서 발급)
      SMS_SENDER         : 발신번호 (예: "0212345678")
    """

    async def send(self, phone: str, message: str) -> None:
        if not (settings.SMS_SERVICE_ID and settings.SMS_API_KEY and settings.SMS_API_SECRET and settings.SMS_SENDER):
            raise RuntimeError("NCP Sens 환경변수가 설정되지 않았습니다.")

        url_path = f"/sms/v2/services/{settings.SMS_SERVICE_ID}/messages"
        url = f"{NCP_SENS_BASE}{url_path}"
        timestamp = str(int(time.time() * 1000))

        headers = {
            "Content-Type": "application/json; charset=utf-8",
            "x-ncp-apigw-timestamp": timestamp,
            "x-ncp-iam-access-key": settings.SMS_API_KEY,
            "x-ncp-apigw-signature-v2": _make_signature("POST", url_path, timestamp),
        }
        body = {
            "type": "SMS",
            "contentType": "COMM",
            "countryCode": "82",
            "from": settings.SMS_SENDER,
            "content": message,
            "messages": [{"to": _e164_to_kr_local(phone)}],
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.post(url, json=body, headers=headers)
            if res.status_code >= 400:
                logger.error("NCP Sens 발송 실패: %s %s", res.status_code, res.text)
                raise RuntimeError(f"SMS 발송 실패: {res.status_code}")
