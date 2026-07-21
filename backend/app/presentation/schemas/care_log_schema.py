from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.domain.entities.care_log import CareCategory


class CareLogCreateRequest(BaseModel):
    id: UUID | None = None  # 클라 생성 UUID(멱등 upsert). 생략 시 서버 생성(하위호환).
    category: CareCategory
    name: str | None = None
    dose: str | None = None
    recorded_at: datetime
    memo: str | None = None


class CareLogUpdateRequest(BaseModel):
    category: CareCategory
    name: str | None = None
    dose: str | None = None
    recorded_at: datetime
    memo: str | None = None


class CareLogResponse(BaseModel):
    id: UUID
    baby_id: UUID
    category: CareCategory
    name: str | None
    dose: str | None
    recorded_at: datetime
    memo: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
