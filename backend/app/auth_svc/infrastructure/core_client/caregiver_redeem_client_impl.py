from uuid import UUID

import httpx

from app.auth_svc.application.interfaces.caregiver_redeem_client import (
    CaregiverRedeemClient,
    InvalidInviteCodeError,
)


class HttpCaregiverRedeemClient(CaregiverRedeemClient):
    """core-service `POST /internal/caregiver/redeem` 를 X-Internal-Key 로 호출."""

    def __init__(self, core_url: str, internal_key: str) -> None:
        self._core_url = core_url.rstrip("/")
        self._internal_key = internal_key

    async def redeem(self, code: str, user_id: UUID) -> UUID:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                f"{self._core_url}/internal/caregiver/redeem",
                headers={"X-Internal-Key": self._internal_key},
                json={"code": code, "user_id": str(user_id)},
            )
        if resp.status_code == 400:
            detail = "유효하지 않은 초대코드입니다."
            try:
                detail = resp.json().get("detail", detail)
            except Exception:
                pass
            raise InvalidInviteCodeError(detail)
        resp.raise_for_status()
        return UUID(resp.json()["baby_id"])
