from dataclasses import dataclass
from datetime import date, datetime
from uuid import UUID


@dataclass
class CreateBabyDTO:
    user_id: UUID
    name: str
    birth_date: date
    gender: str | None = None
    birth_weight_g: int | None = None
    birth_height_cm: float | None = None
    birth_head_circumference_cm: float | None = None
    birth_chest_circumference_cm: float | None = None
    blood_type: str | None = None
    rh_factor: str | None = None
    birth_time: str | None = None


@dataclass
class UpdateBabyDTO:
    id: UUID
    name: str | None = None
    birth_date: date | None = None
    gender: str | None = None
    birth_weight_g: int | None = None
    photo_url: str | None = None
    birth_height_cm: float | None = None
    birth_head_circumference_cm: float | None = None
    birth_chest_circumference_cm: float | None = None
    blood_type: str | None = None
    rh_factor: str | None = None
    birth_time: str | None = None


@dataclass
class BabyResponseDTO:
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
