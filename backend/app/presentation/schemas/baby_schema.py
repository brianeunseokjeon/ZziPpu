from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.domain.value_objects.blood_type import BloodType
from app.domain.value_objects.rh_factor import RhFactor

# "HH:mm" 24h — 00:00 ~ 23:59
_BIRTH_TIME_PATTERN = r"^([01][0-9]|2[0-3]):[0-5][0-9]$"


class BabyCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    birth_date: date
    gender: str | None = None
    birth_weight_g: int | None = Field(None, gt=0)
    birth_height_cm: float | None = Field(None, gt=0)
    birth_head_circumference_cm: float | None = Field(None, gt=0)
    birth_chest_circumference_cm: float | None = Field(None, gt=0)
    blood_type: BloodType | None = None
    rh_factor: RhFactor | None = None
    birth_time: str | None = Field(None, pattern=_BIRTH_TIME_PATTERN)


class BabyUpdateRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    birth_date: date | None = None
    gender: str | None = None
    birth_weight_g: int | None = Field(None, gt=0)
    photo_url: str | None = None
    birth_height_cm: float | None = Field(None, gt=0)
    birth_head_circumference_cm: float | None = Field(None, gt=0)
    birth_chest_circumference_cm: float | None = Field(None, gt=0)
    blood_type: BloodType | None = None
    rh_factor: RhFactor | None = None
    birth_time: str | None = Field(None, pattern=_BIRTH_TIME_PATTERN)


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
    birth_height_cm: float | None = None
    birth_head_circumference_cm: float | None = None
    birth_chest_circumference_cm: float | None = None
    blood_type: str | None = None
    rh_factor: str | None = None
    birth_time: str | None = None

    model_config = {"from_attributes": True}
