from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.application.dto.feeding_dto import CreateFeedingDTO, UpdateFeedingDTO
from app.application.use_cases.feeding import (
    CreateFeedingUseCase,
    DeleteFeedingUseCase,
    GetFeedingsUseCase,
    UpdateFeedingUseCase,
)
from app.presentation.dependencies import (
    CurrentUserDep,
    get_create_feeding_use_case,
    get_delete_feeding_use_case,
    get_get_feedings_use_case,
    get_update_feeding_use_case,
)
from app.presentation.schemas.feeding_schema import (
    FeedingCreateRequest,
    FeedingResponse,
    FeedingUpdateRequest,
)

router = APIRouter(prefix="/babies/{baby_id}/feedings", tags=["feedings"])


@router.post("", response_model=FeedingResponse, status_code=status.HTTP_201_CREATED)
async def create_feeding(
    baby_id: UUID,
    body: FeedingCreateRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[CreateFeedingUseCase, Depends(get_create_feeding_use_case)],
) -> FeedingResponse:
    dto = CreateFeedingDTO(
        baby_id=baby_id,
        id=body.id,
        feeding_type=body.feeding_type,
        started_at=body.started_at,
        ended_at=body.ended_at,
        amount_ml=body.amount_ml,
        duration_minutes=body.duration_minutes,
        memo=body.memo,
        did_vomit=body.did_vomit,
    )
    result = await use_case.execute(dto)
    return FeedingResponse(
        id=result.id,
        baby_id=result.baby_id,
        feeding_type=result.feeding_type,
        started_at=result.started_at,
        ended_at=result.ended_at,
        amount_ml=result.amount_ml,
        duration_minutes=result.duration_minutes,
        memo=result.memo,
        did_vomit=result.did_vomit,
        created_at=result.created_at,
    )


@router.get("", response_model=list[FeedingResponse])
async def get_feedings(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetFeedingsUseCase, Depends(get_get_feedings_use_case)],
    target_date: date = Query(default_factory=date.today, alias="date"),
) -> list[FeedingResponse]:
    results = await use_case.execute(baby_id, target_date)
    return [
        FeedingResponse(
            id=r.id,
            baby_id=r.baby_id,
            feeding_type=r.feeding_type,
            started_at=r.started_at,
            ended_at=r.ended_at,
            amount_ml=r.amount_ml,
            duration_minutes=r.duration_minutes,
            memo=r.memo,
            did_vomit=r.did_vomit,
            created_at=r.created_at,
        )
        for r in results
    ]


@router.patch("/{feeding_id}", response_model=FeedingResponse)
async def update_feeding(
    baby_id: UUID,
    feeding_id: UUID,
    body: FeedingUpdateRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[UpdateFeedingUseCase, Depends(get_update_feeding_use_case)],
) -> FeedingResponse:
    dto = UpdateFeedingDTO(
        id=feeding_id,
        feeding_type=body.feeding_type,
        started_at=body.started_at,
        ended_at=body.ended_at,
        amount_ml=body.amount_ml,
        duration_minutes=body.duration_minutes,
        memo=body.memo,
        did_vomit=body.did_vomit,
    )
    try:
        result = await use_case.execute(dto)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    return FeedingResponse(
        id=result.id,
        baby_id=result.baby_id,
        feeding_type=result.feeding_type,
        started_at=result.started_at,
        ended_at=result.ended_at,
        amount_ml=result.amount_ml,
        duration_minutes=result.duration_minutes,
        memo=result.memo,
        did_vomit=result.did_vomit,
        created_at=result.created_at,
    )


@router.delete("/{feeding_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_feeding(
    baby_id: UUID,
    feeding_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[DeleteFeedingUseCase, Depends(get_delete_feeding_use_case)],
) -> None:
    await use_case.execute(feeding_id)
