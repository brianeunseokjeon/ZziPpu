from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class CreatePlayDTO:
    baby_id: UUID
    play_type: str
    started_at: datetime
    ended_at: datetime | None = None
    duration_minutes: int | None = None
    memo: str | None = None
    id: UUID | None = None  # 클라 생성 UUID(멱등 upsert)


@dataclass
class PlayResponseDTO:
    id: UUID
    baby_id: UUID
    play_type: str
    started_at: datetime
    ended_at: datetime | None
    duration_minutes: int | None
    memo: str | None
    created_at: datetime
