from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class BabyCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    birth_date: date
    gender: str | None = None
    birth_weight_g: int | None = Field(None, gt=0)


class BabyUpdateRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    birth_date: date | None = None
    gender: str | None = None
    birth_weight_g: int | None = Field(None, gt=0)
    photo_url: str | None = None


class BabyResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    birth_date: date
    gender: str | None
    birth_weight_g: int | None
    age_days: int
    age_months: int
    created_at: datetime
    photo_url: str | None = None

    model_config = {"from_attributes": True}
