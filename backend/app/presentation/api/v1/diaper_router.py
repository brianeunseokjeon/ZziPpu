from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status

from app.application.dto.diaper_dto import CreateDiaperDTO
from app.application.use_cases.diaper import (
    CreateDiaperRecordUseCase,
    DeleteDiaperUseCase,
    GetDiaperRecordsUseCase,
)
from app.presentation.dependencies import (
    CurrentUserDep,
    get_create_diaper_use_case,
    get_delete_diaper_use_case,
    get_get_diapers_use_case,
)
from app.presentation.schemas.diaper_schema import DiaperCreateRequest, DiaperResponse

router = APIRouter(prefix="/babies/{baby_id}/diapers", tags=["diapers"])


@router.post("", response_model=DiaperResponse, status_code=status.HTTP_201_CREATED)
async def create_diaper(
    baby_id: UUID,
    body: DiaperCreateRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[CreateDiaperRecordUseCase, Depends(get_create_diaper_use_case)],
) -> DiaperResponse:
    dto = CreateDiaperDTO(
        baby_id=baby_id,
        id=body.id,
        recorded_at=body.recorded_at,
        diaper_type=body.diaper_type,
        stool_color=body.stool_color,
        stool_state=body.stool_state,
        memo=body.memo,
    )
    result = await use_case.execute(dto)
    return DiaperResponse(
        id=result.id,
        baby_id=result.baby_id,
        recorded_at=result.recorded_at,
        diaper_type=result.diaper_type,
        stool_color=result.stool_color,
        stool_state=result.stool_state,
        memo=result.memo,
        created_at=result.created_at,
    )


@router.get("", response_model=list[DiaperResponse])
async def get_diapers(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetDiaperRecordsUseCase, Depends(get_get_diapers_use_case)],
    target_date: date = Query(default_factory=date.today, alias="date"),
) -> list[DiaperResponse]:
    results = await use_case.execute(baby_id, target_date)
    return [
        DiaperResponse(
            id=r.id,
            baby_id=r.baby_id,
            recorded_at=r.recorded_at,
            diaper_type=r.diaper_type,
            stool_color=r.stool_color,
            stool_state=r.stool_state,
            memo=r.memo,
            created_at=r.created_at,
        )
        for r in results
    ]


@router.delete("/{diaper_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_diaper(
    baby_id: UUID,
    diaper_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[DeleteDiaperUseCase, Depends(get_delete_diaper_use_case)],
) -> None:
    await use_case.execute(diaper_id)
