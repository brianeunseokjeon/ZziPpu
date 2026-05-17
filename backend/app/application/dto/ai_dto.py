from dataclasses import dataclass, field
from datetime import date
from uuid import UUID


@dataclass
class DailyReviewDTO:
    baby_id: UUID
    review_date: date
    feeding_analysis: str
    sleep_analysis: str
    diaper_analysis: str
    play_analysis: str
    overall_assessment: str
    alerts: list[str]
    recommendations: list[str]
    positives: list[str] = field(default_factory=list)
    considerations: list[str] = field(default_factory=list)
    concerns: list[str] = field(default_factory=list)
    critical_warnings: list[str] = field(default_factory=list)


@dataclass
class ChatRequestDTO:
    baby_id: UUID
    conversation_id: UUID | None
    message: str


@dataclass
class ChatResponseDTO:
    conversation_id: UUID
    message: str
    role: str = "assistant"
