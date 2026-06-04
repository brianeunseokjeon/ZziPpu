from typing import Literal

from pydantic import BaseModel


class ParentActionResponse(BaseModel):
    icon: str
    title: str
    detail: str
    source: str
    priority: Literal["high", "medium", "low"]


class DevelopmentStageResponse(BaseModel):
    age_range_days: tuple[int, int]
    label: str
    summary: str
    # K-DST 6영역
    gross_motor: list[str]
    fine_motor: list[str]
    cognition: list[str]
    language: list[str]
    social: list[str]
    self_care: list[str]
    parent_actions: list[ParentActionResponse]
    warning_signs: list[str]
    feeding_summary: str
    sleep_summary: str
    play_summary: str
    sources: list[str]


class CurrentStageBundleResponse(BaseModel):
    """현재 시기 + 이전/다음 시기를 한 번에 반환 (네비게이션용)."""
    current: DevelopmentStageResponse
    previous: DevelopmentStageResponse | None
    next: DevelopmentStageResponse | None
    age_days: int


class MilestoneResponse(BaseModel):
    days: int
    label: str
    emoji: str
    category: Literal["celebration", "checkup", "developmental"]
    description: str
