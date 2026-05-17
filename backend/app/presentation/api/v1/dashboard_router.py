from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.application.use_cases.dashboard import GetDailySummaryUseCase
from app.presentation.dependencies import (
    CurrentUserDep,
    get_daily_summary_use_case,
)
from app.presentation.schemas.dashboard_schema import DailySummaryResponse

router = APIRouter(prefix="/babies/{baby_id}/dashboard", tags=["dashboard"])


@router.get("/daily", response_model=DailySummaryResponse)
async def get_daily_summary(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetDailySummaryUseCase, Depends(get_daily_summary_use_case)],
    target_date: date = Query(default_factory=date.today, alias="date"),
) -> DailySummaryResponse:
    result = await use_case.execute(baby_id, target_date)
    return DailySummaryResponse(
        total_feeding_ml=result.total_feeding_ml,
        feeding_count=result.feeding_count,
        total_sleep_minutes=result.total_sleep_minutes,
        sleep_count=result.sleep_count,
        diaper_count=result.diaper_count,
        poop_count=result.poop_count,
        pee_count=result.pee_count,
        total_play_minutes=result.total_play_minutes,
        tummy_time_minutes=result.tummy_time_minutes,
        last_feeding_at=result.last_feeding_at,
        last_diaper_at=result.last_diaper_at,
        last_sleep_at=result.last_sleep_at,
    )
