from dataclasses import dataclass
from datetime import date, datetime
from uuid import UUID


@dataclass
class Vaccination:
    id: UUID
    baby_id: UUID
    vaccine_name: str
    dose_number: int
    scheduled_date: date
    administered_date: date | None
    hospital_name: str | None
    memo: str | None
    created_at: datetime
