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
