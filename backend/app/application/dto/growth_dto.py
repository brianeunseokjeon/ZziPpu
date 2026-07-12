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
class UpdateGrowthDTO:
    # 전체 교체(PUT류). record_id로 조회 후 baby_id 소유권 검증에 사용.
    baby_id: UUID
    record_id: UUID
    recorded_at: date | None = None
    weight_g: int | None = None
    height_cm: float | None = None
    head_circumference_cm: float | None = None
    memo: str | None = None


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
