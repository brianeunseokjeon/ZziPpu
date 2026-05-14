from dataclasses import dataclass
from datetime import datetime


@dataclass
class DailySummaryDTO:
    feeding_count: int
    total_ml: int
    sleep_total_minutes: int
    diaper_count: int
    play_total_minutes: int
    last_feeding_at: datetime | None
    last_diaper_at: datetime | None
    last_sleep_at: datetime | None
