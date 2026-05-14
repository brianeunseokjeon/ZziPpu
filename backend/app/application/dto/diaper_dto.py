from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

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
    memo: str | None = None


@dataclass
class DiaperResponseDTO:
    id: UUID
    baby_id: UUID
    recorded_at: datetime
    diaper_type: DiaperType
    stool_color: StoolColor | None
    stool_state: StoolState | None
    memo: str | None
    created_at: datetime
