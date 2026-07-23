from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from uuid import UUID


class CareCategory(str, Enum):
    BATH = "bath"
    SUPPLEMENT = "supplement"
    MEDICINE = "medicine"
    HOSPITAL = "hospital"


@dataclass
class CareLog:
    id: UUID
    baby_id: UUID
    category: CareCategory
    name: str | None
    dose: str | None
    recorded_at: datetime
    memo: str | None
    created_at: datetime
