from datetime import datetime

from pydantic import BaseModel


class DailySummaryResponse(BaseModel):
    total_feeding_ml: int
    feeding_count: int
    total_sleep_minutes: int
    sleep_count: int
    diaper_count: int
    poop_count: int
    pee_count: int
    total_play_minutes: int
    tummy_time_minutes: int
    last_feeding_at: datetime | None
    last_diaper_at: datetime | None
    last_sleep_at: datetime | None
