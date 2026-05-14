from dataclasses import dataclass, field
from datetime import date, datetime
from uuid import UUID


@dataclass
class AIReview:
    id: UUID
    baby_id: UUID
    review_date: date
    feeding_analysis: str
    sleep_analysis: str
    diaper_analysis: str
    play_analysis: str
    overall_assessment: str
    alerts: list[str]
    recommendations: list[str]
    created_at: datetime
