from dataclasses import dataclass
from datetime import date, datetime
from uuid import UUID


@dataclass
class CreateGrowthDTO:
    baby_id: UUID
    recorded_at: date
    weight_g: int | None = None
    height_cm: float | None = None
    head_circumference_cm: float | None = None
    memo: str | None = None
    id: UUID | None = None  # 클라 생성 UUID(멱등 upsert)


@dataclass
class GrowthResponseDTO:
    id: UUID
    baby_id: UUID
    recorded_at: date
    weight_g: int | None
    height_cm: float | None
    head_circumference_cm: float | None
    memo: str | None
    created_at: datetime
