from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field


class DailyReviewRequest(BaseModel):
    review_date: date = Field(default_factory=date.today)


class DailyReviewResponse(BaseModel):
    baby_id: UUID
    review_date: date
    feeding_analysis: str
    sleep_analysis: str
    diaper_analysis: str
    play_analysis: str
    overall_assessment: str
    alerts: list[str]
    recommendations: list[str]
    positives: list[str] = Field(default_factory=list)
    considerations: list[str] = Field(default_factory=list)
    concerns: list[str] = Field(default_factory=list)
    critical_warnings: list[str] = Field(default_factory=list)


class ChatRequest(BaseModel):
    conversation_id: UUID | None = None
    message: str = Field(..., min_length=1)


class ChatResponse(BaseModel):
    conversation_id: UUID
    message: str
    role: str = "assistant"


class SaveInfoRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    content: str = Field(..., min_length=1)
    category: str = Field(..., min_length=1, max_length=50)
    chat_message_id: UUID | None = None


class SavedInfoResponse(BaseModel):
    id: UUID
    baby_id: UUID
    title: str
    content: str
    category: str
    chat_message_id: UUID | None
    created_at: str
