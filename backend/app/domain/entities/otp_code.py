from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class OtpCode:
    """
    SMS OTP 인증 코드.

    - DB에는 평문 code 대신 bcrypt hash만 저장.
    - 1회용. 검증 성공 시 verified=True.
    - 5분 만료, 5회 시도 후 무효.
    """

    id: UUID
    phone: str             # E.164 (예: +821012345678)
    code_hash: str         # bcrypt hash
    expires_at: datetime
    verified: bool
    attempts: int
    created_at: datetime
    request_ip: str | None = None
