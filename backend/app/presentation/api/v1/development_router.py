"""
발달 가이드 + 마일스톤 API.

AI 채팅·일일 리뷰가 사용하는 도메인 데이터(`developmental_milestones.py`)를
프론트엔드 발달 가이드 페이지에 그대로 노출. 단일 출처.
"""
from fastapi import APIRouter, Query

from app.domain.guidelines.developmental_milestones import (
    DEVELOPMENT_STAGES,
    MILESTONES,
    DevelopmentStage,
    Milestone,
    ParentAction,
    get_neighboring_stages,
)
from app.presentation.schemas.development_schema import (
    CurrentStageBundleResponse,
    DevelopmentStageResponse,
    MilestoneResponse,
    ParentActionResponse,
)

router = APIRouter(prefix="/development", tags=["development"])


def _to_action(a: ParentAction) -> ParentActionResponse:
    return ParentActionResponse(
        icon=a.icon,
        title=a.title,
        detail=a.detail,
        source=a.source,
        priority=a.priority,
    )


def _to_stage(s: DevelopmentStage) -> DevelopmentStageResponse:
    return DevelopmentStageResponse(
        age_range_days=s.age_range_days,
        label=s.label,
        summary=s.summary,
        gross_motor=list(s.gross_motor),
        fine_motor=list(s.fine_motor),
        cognition=list(s.cognition),
        language=list(s.language),
        social=list(s.social),
        self_care=list(s.self_care),
        parent_actions=[_to_action(a) for a in s.parent_actions],
        warning_signs=list(s.warning_signs),
        feeding_summary=s.feeding_summary,
        sleep_summary=s.sleep_summary,
        play_summary=s.play_summary,
        sources=list(s.sources),
    )


def _to_milestone(m: Milestone) -> MilestoneResponse:
    return MilestoneResponse(
        days=m.days,
        label=m.label,
        emoji=m.emoji,
        category=m.category,
        description=m.description,
    )


@router.get("/stages", response_model=list[DevelopmentStageResponse])
async def list_stages() -> list[DevelopmentStageResponse]:
    """전체 발달 시기 (네비게이션·전체 보기용)."""
    return [_to_stage(s) for s in DEVELOPMENT_STAGES]


@router.get("/stages/current", response_model=CurrentStageBundleResponse)
async def get_current_stage(
    age_days: int = Query(..., ge=0, description="생후 일수 (한국식: 생일 당일 = 1)"),
) -> CurrentStageBundleResponse:
    """주어진 생후 일수의 현재 시기 + 이전·다음 시기."""
    prev, current, nxt = get_neighboring_stages(age_days)
    return CurrentStageBundleResponse(
        current=_to_stage(current),
        previous=_to_stage(prev) if prev else None,
        next=_to_stage(nxt) if nxt else None,
        age_days=age_days,
    )


@router.get("/milestones", response_model=list[MilestoneResponse])
async def list_milestones() -> list[MilestoneResponse]:
    """마일스톤 정적 데이터 (50일·백일·돌 등)."""
    return [_to_milestone(m) for m in MILESTONES]
