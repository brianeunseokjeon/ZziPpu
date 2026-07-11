from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class CreateSleepDTO:
    baby_id: UUID
    started_at: datetime
    ended_at: datetime | None = None
    memo: str | None = None


@dataclass
class StartSleepDTO:
    baby_id: UUID
    started_at: datetime
    memo: str | None = None
    id: UUID | None = None  # 클라 생성 UUID(멱등 upsert)


@dataclass
class EndSleepDTO:
    sleep_id: UUID
    ended_at: datetime


@dataclass
class SleepResponseDTO:
    id: UUID
    baby_id: UUID
    started_at: datetime
    ended_at: datetime | None
    duration_minutes: int | None
    memo: str | None
    created_at: datetime
