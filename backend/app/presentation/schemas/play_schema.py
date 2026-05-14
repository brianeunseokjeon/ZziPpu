from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class PlayCreateRequest(BaseModel):
    play_type: str = Field(..., min_length=1, max_length=50)
    started_at: datetime
    ended_at: datetime | None = None
    duration_minutes: int | None = Field(None, gt=0)
    memo: str | None = None


class PlayResponse(BaseModel):
    id: UUID
    baby_id: UUID
    play_type: str
    started_at: datetime
    ended_at: datetime | None
    duration_minutes: int | None
    memo: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
