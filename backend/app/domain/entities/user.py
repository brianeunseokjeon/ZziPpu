from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class User:
    id: UUID
    email: str | None
    name: str | None
    created_at: datetime
    phone: str | None = None  # E.164 정규화된 핸드폰 번호 (예: +821012345678)
