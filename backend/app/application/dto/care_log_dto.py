from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from app.domain.entities.care_log import CareCategory


@dataclass
class CreateCareLogDTO:
    baby_id: UUID
    category: CareCategory
    recorded_at: datetime
    name: str | None = None
    dose: str | None = None
    memo: str | None = None
    id: UUID | None = None  # 클라 생성 UUID(멱등 upsert)


@dataclass
class UpdateCareLogDTO:
    id: UUID
    category: CareCategory
    recorded_at: datetime
    name: str | None = None
    dose: str | None = None
    memo: str | None = None


@dataclass
class CareLogResponseDTO:
    id: UUID
    baby_id: UUID
    category: CareCategory
    name: str | None
    dose: str | None
    recorded_at: datetime
    memo: str | None
    created_at: datetime
