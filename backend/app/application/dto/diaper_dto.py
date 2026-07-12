from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from app.domain.value_objects.diaper_amount import DiaperAmount
from app.domain.value_objects.diaper_type import DiaperType
from app.domain.value_objects.stool_color import StoolColor
from app.domain.value_objects.stool_state import StoolState


@dataclass
class CreateDiaperDTO:
    baby_id: UUID
    recorded_at: datetime
    diaper_type: DiaperType
    stool_color: StoolColor | None = None
    stool_state: StoolState | None = None
    amount: DiaperAmount | None = None
    memo: str | None = None
    id: UUID | None = None  # 클라 생성 UUID(멱등 upsert)


@dataclass
class DiaperResponseDTO:
    id: UUID
    baby_id: UUID
    recorded_at: datetime
    diaper_type: DiaperType
    stool_color: StoolColor | None
    stool_state: StoolState | None
    amount: DiaperAmount | None
    memo: str | None
    created_at: datetime
