from dataclasses import dataclass
from datetime import date, datetime
from uuid import UUID


@dataclass
class GrowthRecord:
    id: UUID
    baby_id: UUID
    recorded_at: date
    weight_g: int | None
    height_cm: float | None
    head_circumference_cm: float | None
    temperature_c: float | None
    memo: str | None
    created_at: datetime
