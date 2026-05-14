from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status

from app.application.dto.growth_dto import CreateGrowthDTO
from app.application.use_cases.growth import (
    CreateGrowthRecordUseCase,
    DeleteGrowthRecordUseCase,
    GetGrowthRecordsUseCase,
)
from app.presentation.dependencies import (
    CurrentUserDep,
    get_create_growth_use_case,
    get_delete_growth_use_case,
    get_get_growth_records_use_case,
)
from app.presentation.schemas.growth_schema import CreateGrowthRequest, GrowthResponse

router = APIRouter(prefix="/babies/{baby_id}/growth", tags=["growth"])


@router.post("", response_model=GrowthResponse, status_code=status.HTTP_201_CREATED)
async def create_growth_record(
    baby_id: UUID,
    body: CreateGrowthRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[CreateGrowthRecordUseCase, Depends(get_create_growth_use_case)],
) -> GrowthResponse:
    dto = CreateGrowthDTO(
        baby_id=baby_id,
        recorded_at=body.recorded_at,
        weight_g=body.weight_g,
        height_cm=body.height_cm,
        head_circumference_cm=body.head_circumference_cm,
        memo=body.memo,
    )
    result = await use_case.execute(dto)
    return GrowthResponse(
        id=result.id,
        baby_id=result.baby_id,
        recorded_at=result.recorded_at,
        weight_g=result.weight_g,
        height_cm=result.height_cm,
        head_circumference_cm=result.head_circumference_cm,
        memo=result.memo,
        created_at=result.created_at,
    )


@router.get("", response_model=list[GrowthResponse])
async def get_growth_records(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetGrowthRecordsUseCase, Depends(get_get_growth_records_use_case)],
) -> list[GrowthResponse]:
    results = await use_case.execute(baby_id)
    return [
        GrowthResponse(
            id=r.id,
            baby_id=r.baby_id,
            recorded_at=r.recorded_at,
            weight_g=r.weight_g,
            height_cm=r.height_cm,
            head_circumference_cm=r.head_circumference_cm,
            memo=r.memo,
            created_at=r.created_at,
        )
        for r in results
    ]


@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_growth_record(
    baby_id: UUID,
    record_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[DeleteGrowthRecordUseCase, Depends(get_delete_growth_use_case)],
) -> None:
    await use_case.execute(record_id)
