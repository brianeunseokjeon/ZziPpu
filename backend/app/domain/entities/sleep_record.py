from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class SleepRecord:
    id: UUID
    baby_id: UUID
    started_at: datetime
    ended_at: datetime | None
    memo: str | None
    created_at: datetime

    @property
    def duration_minutes(self) -> int | None:
        if self.ended_at is None:
            return None
        delta = self.ended_at - self.started_at
        return int(delta.total_seconds() / 60)
