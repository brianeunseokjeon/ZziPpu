from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status

from app.application.dto.care_log_dto import CreateCareLogDTO, UpdateCareLogDTO
from app.application.use_cases.care_log import (
    CreateCareLogUseCase,
    DeleteCareLogUseCase,
    GetCareLogsUseCase,
    UpdateCareLogUseCase,
)
from app.presentation.dependencies import (
    CurrentUserDep,
    get_create_care_log_use_case,
    get_delete_care_log_use_case,
    get_get_care_logs_use_case,
    get_update_care_log_use_case,
)
from app.presentation.schemas.care_log_schema import (
    CareLogCreateRequest,
    CareLogResponse,
    CareLogUpdateRequest,
)

router = APIRouter(prefix="/babies/{baby_id}/care-logs", tags=["care-logs"])


@router.post("", response_model=CareLogResponse, status_code=status.HTTP_201_CREATED)
async def create_care_log(
    baby_id: UUID,
    body: CareLogCreateRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[CreateCareLogUseCase, Depends(get_create_care_log_use_case)],
) -> CareLogResponse:
    dto = CreateCareLogDTO(
        baby_id=baby_id,
        id=body.id,
        category=body.category,
        name=body.name,
        dose=body.dose,
        recorded_at=body.recorded_at,
        memo=body.memo,
    )
    result = await use_case.execute(dto)
    return CareLogResponse(
        id=result.id,
        baby_id=result.baby_id,
        category=result.category,
        name=result.name,
        dose=result.dose,
        recorded_at=result.recorded_at,
        memo=result.memo,
        created_at=result.created_at,
    )


@router.get("", response_model=list[CareLogResponse])
async def get_care_logs(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetCareLogsUseCase, Depends(get_get_care_logs_use_case)],
    target_date: date = Query(default_factory=date.today, alias="date"),
) -> list[CareLogResponse]:
    results = await use_case.execute(baby_id, target_date)
    return [
        CareLogResponse(
            id=r.id,
            baby_id=r.baby_id,
            category=r.category,
            name=r.name,
            dose=r.dose,
            recorded_at=r.recorded_at,
            memo=r.memo,
            created_at=r.created_at,
        )
        for r in results
    ]


@router.patch("/{care_log_id}", response_model=CareLogResponse)
async def update_care_log(
    baby_id: UUID,
    care_log_id: UUID,
    body: CareLogUpdateRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[UpdateCareLogUseCase, Depends(get_update_care_log_use_case)],
) -> CareLogResponse:
    dto = UpdateCareLogDTO(
        id=care_log_id,
        category=body.category,
        name=body.name,
        dose=body.dose,
        recorded_at=body.recorded_at,
        memo=body.memo,
    )
    result = await use_case.execute(dto)
    return CareLogResponse(
        id=result.id,
        baby_id=result.baby_id,
        category=result.category,
        name=result.name,
        dose=result.dose,
        recorded_at=result.recorded_at,
        memo=result.memo,
        created_at=result.created_at,
    )


@router.delete("/{care_log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_care_log(
    baby_id: UUID,
    care_log_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[DeleteCareLogUseCase, Depends(get_delete_care_log_use_case)],
) -> None:
    await use_case.execute(care_log_id)
