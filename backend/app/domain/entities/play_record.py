from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class PlayRecord:
    id: UUID
    baby_id: UUID
    play_type: str
    started_at: datetime
    ended_at: datetime | None
    duration_minutes: int | None
    memo: str | None
    created_at: datetime
