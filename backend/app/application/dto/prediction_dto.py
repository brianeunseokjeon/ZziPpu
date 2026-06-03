from dataclasses import dataclass
from datetime import datetime


@dataclass
class PredictionDTO:
    last_feeding_at: datetime | None
    next_feeding_at: datetime | None
    feeding_interval_minutes: int | None
    feeding_based_on: int
    last_sleep_ended_at: datetime | None
    next_sleep_at: datetime | None
    awake_window_minutes: int | None
    sleep_based_on: int
