from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.domain.value_objects.feeding_type import FeedingType


class FeedingCreateRequest(BaseModel):
    id: UUID | None = None  # 클라 생성 UUID(멱등 upsert). 생략 시 서버 생성(하위호환).
    feeding_type: FeedingType
    started_at: datetime
    ended_at: datetime | None = None
    amount_ml: int | None = Field(None, gt=0)
    duration_minutes: int | None = Field(None, gt=0)
    memo: str | None = None


class FeedingUpdateRequest(BaseModel):
    feeding_type: FeedingType
    started_at: datetime
    ended_at: datetime | None = None
    amount_ml: int | None = Field(None, gt=0)
    duration_minutes: int | None = Field(None, gt=0)
    memo: str | None = None


class FeedingResponse(BaseModel):
    id: UUID
    baby_id: UUID
    feeding_type: FeedingType
    started_at: datetime
    ended_at: datetime | None
    amount_ml: int | None
    duration_minutes: int | None
    memo: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
