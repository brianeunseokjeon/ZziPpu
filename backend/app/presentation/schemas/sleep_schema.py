from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class SleepStartRequest(BaseModel):
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
