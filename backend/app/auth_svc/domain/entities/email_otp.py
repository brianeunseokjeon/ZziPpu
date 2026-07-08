from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class EmailOtp:
    """이메일로 발송된 1회용 인증 코드 (해시 저장)."""

    id: UUID
    email: str
    code_hash: str
    expires_at: datetime
    verified: bool
    attempts: int
    created_at: datetime
    request_ip: str | None = None
