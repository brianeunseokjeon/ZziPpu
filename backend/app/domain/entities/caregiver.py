from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class Caregiver:
    id: UUID
    baby_id: UUID
    user_id: UUID
    role: str
    created_at: datetime


@dataclass
class CaregiverInvite:
    id: UUID
    baby_id: UUID
    code: str
    created_by: UUID
    expires_at: datetime
    used_at: datetime | None
    created_at: datetime
