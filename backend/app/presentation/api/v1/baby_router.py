from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.application.dto.baby_dto import CreateBabyDTO
from app.application.use_cases.baby import RegisterBabyUseCase, GetBabyProfileUseCase
from app.presentation.dependencies import (
    CurrentUserDep,
    get_register_baby_use_case,
    get_baby_profile_use_case,
)
from app.presentation.schemas.baby_schema import BabyCreateRequest, BabyResponse

router = APIRouter(prefix="/babies", tags=["babies"])


@router.post("", response_model=BabyResponse, status_code=status.HTTP_201_CREATED)
async def register_baby(
    body: BabyCreateRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[RegisterBabyUseCase, Depends(get_register_baby_use_case)],
) -> BabyResponse:
    dto = CreateBabyDTO(
        user_id=user_id,
        name=body.name,
        birth_date=body.birth_date,
        gender=body.gender,
        birth_weight_g=body.birth_weight_g,
    )
    result = await use_case.execute(dto)
    return BabyResponse(
        id=result.id,
        user_id=result.user_id,
        name=result.name,
        birth_date=result.birth_date,
        gender=result.gender,
        birth_weight_g=result.birth_weight_g,
        age_days=result.age_days,
        age_months=result.age_months,
        created_at=result.created_at,
    )


@router.get("", response_model=list[BabyResponse])
async def list_babies(
    user_id: CurrentUserDep,
    use_case: Annotated[GetBabyProfileUseCase, Depends(get_baby_profile_use_case)],
) -> list[BabyResponse]:
    results = await use_case.get_by_user(user_id)
    return [
        BabyResponse(
            id=r.id,
            user_id=r.user_id,
            name=r.name,
            birth_date=r.birth_date,
            gender=r.gender,
            birth_weight_g=r.birth_weight_g,
            age_days=r.age_days,
            age_months=r.age_months,
            created_at=r.created_at,
        )
        for r in results
    ]


@router.get("/{baby_id}", response_model=BabyResponse)
async def get_baby(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetBabyProfileUseCase, Depends(get_baby_profile_use_case)],
) -> BabyResponse:
    result = await use_case.execute(baby_id)
    if result is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Baby not found")
    return BabyResponse(
        id=result.id,
        user_id=result.user_id,
        name=result.name,
        birth_date=result.birth_date,
        gender=result.gender,
        birth_weight_g=result.birth_weight_g,
        age_days=result.age_days,
        age_months=result.age_months,
        created_at=result.created_at,
    )
