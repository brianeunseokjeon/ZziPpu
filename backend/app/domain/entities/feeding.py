from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from app.domain.value_objects.feeding_type import FeedingType


@dataclass
class Feeding:
    id: UUID
    baby_id: UUID
    feeding_type: FeedingType
    started_at: datetime
    ended_at: datetime | None
    amount_ml: int | None
    duration_minutes: int | None
    memo: str | None
    did_vomit: bool
    created_at: datetime
