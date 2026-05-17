from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.application.dto.sleep_dto import StartSleepDTO, EndSleepDTO
from app.application.use_cases.sleep import (
    StartSleepUseCase,
    EndSleepUseCase,
    GetSleepRecordsUseCase,
    DeleteSleepUseCase,
)
from app.presentation.dependencies import (
    CurrentUserDep,
    get_start_sleep_use_case,
    get_end_sleep_use_case,
    get_get_sleeps_use_case,
    get_delete_sleep_use_case,
)
from app.presentation.schemas.sleep_schema import SleepStartRequest, SleepEndRequest, SleepResponse

router = APIRouter(prefix="/babies/{baby_id}/sleeps", tags=["sleeps"])


@router.post("", response_model=SleepResponse, status_code=status.HTTP_201_CREATED)
async def start_sleep(
    baby_id: UUID,
    body: SleepStartRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[StartSleepUseCase, Depends(get_start_sleep_use_case)],
) -> SleepResponse:
    dto = StartSleepDTO(
        baby_id=baby_id,
        started_at=body.started_at,
        memo=body.memo,
    )
    result = await use_case.execute(dto)
    return SleepResponse(
        id=result.id,
        baby_id=result.baby_id,
        started_at=result.started_at,
        ended_at=result.ended_at,
        duration_minutes=result.duration_minutes,
        memo=result.memo,
        created_at=result.created_at,
    )


@router.put("/{sleep_id}/end", response_model=SleepResponse)
async def end_sleep(
    baby_id: UUID,
    sleep_id: UUID,
    body: SleepEndRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[EndSleepUseCase, Depends(get_end_sleep_use_case)],
) -> SleepResponse:
    dto = EndSleepDTO(
        sleep_id=sleep_id,
        ended_at=body.ended_at,
    )
    try:
        result = await use_case.execute(dto)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    return SleepResponse(
        id=result.id,
        baby_id=result.baby_id,
        started_at=result.started_at,
        ended_at=result.ended_at,
        duration_minutes=result.duration_minutes,
        memo=result.memo,
        created_at=result.created_at,
    )


@router.get("", response_model=list[SleepResponse])
async def get_sleeps(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetSleepRecordsUseCase, Depends(get_get_sleeps_use_case)],
    target_date: date = Query(default_factory=date.today, alias="date"),
) -> list[SleepResponse]:
    results = await use_case.execute(baby_id, target_date)
    return [
        SleepResponse(
            id=r.id,
            baby_id=r.baby_id,
            started_at=r.started_at,
            ended_at=r.ended_at,
            duration_minutes=r.duration_minutes,
            memo=r.memo,
            created_at=r.created_at,
        )
        for r in results
    ]


@router.get("/active", response_model=SleepResponse | None)
async def get_active_sleep(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetSleepRecordsUseCase, Depends(get_get_sleeps_use_case)],
) -> SleepResponse | None:
    result = await use_case.get_active(baby_id)
    if result is None:
        return None
    return SleepResponse(
        id=result.id,
        baby_id=result.baby_id,
        started_at=result.started_at,
        ended_at=result.ended_at,
        duration_minutes=result.duration_minutes,
        memo=result.memo,
        created_at=result.created_at,
    )


@router.delete("/{sleep_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_sleep(
    baby_id: UUID,
    sleep_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[DeleteSleepUseCase, Depends(get_delete_sleep_use_case)],
) -> None:
    await use_case.execute(sleep_id)
