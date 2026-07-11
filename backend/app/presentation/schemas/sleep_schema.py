from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class SleepStartRequest(BaseModel):
    id: UUID | None = None  # 클라 생성 UUID(멱등 upsert). 생략 시 서버 생성(하위호환).
    started_at: datetime
    memo: str | None = None


class SleepEndRequest(BaseModel):
    ended_at: datetime


class SleepResponse(BaseModel):
    id: UUID
    baby_id: UUID
    started_at: datetime
    ended_at: datetime | None
    duration_minutes: int | None
    memo: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
