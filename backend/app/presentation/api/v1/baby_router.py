from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import Response

from app.application.dto.baby_dto import CreateBabyDTO, UpdateBabyDTO
from app.application.use_cases.baby import (
    GetBabyProfileUseCase,
    RegisterBabyUseCase,
    UpdateBabyUseCase,
)
from app.application.use_cases.export import ExportBabyDataUseCase
from app.presentation.dependencies import (
    CurrentUserDep,
    DbDep,
    get_baby_profile_use_case,
    get_register_baby_use_case,
    get_update_baby_use_case,
)
from app.presentation.schemas.baby_schema import BabyCreateRequest, BabyResponse, BabyUpdateRequest

router = APIRouter(prefix="/babies", tags=["babies"])


def _to_response(result) -> BabyResponse:
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
        photo_url=getattr(result, "photo_url", None),
    )


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
    return _to_response(await use_case.execute(dto))


@router.get("", response_model=list[BabyResponse])
async def list_babies(
    user_id: CurrentUserDep,
    use_case: Annotated[GetBabyProfileUseCase, Depends(get_baby_profile_use_case)],
) -> list[BabyResponse]:
    results = await use_case.get_by_user(user_id)
    return [_to_response(r) for r in results]


@router.get("/{baby_id}", response_model=BabyResponse)
async def get_baby(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetBabyProfileUseCase, Depends(get_baby_profile_use_case)],
) -> BabyResponse:
    result = await use_case.execute(baby_id)
    if result is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Baby not found")
    return _to_response(result)


@router.patch("/{baby_id}", response_model=BabyResponse)
async def update_baby(
    baby_id: UUID,
    body: BabyUpdateRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[UpdateBabyUseCase, Depends(get_update_baby_use_case)],
) -> BabyResponse:
    try:
        dto = UpdateBabyDTO(
            id=baby_id,
            name=body.name,
            birth_date=body.birth_date,
            gender=body.gender,
            birth_weight_g=body.birth_weight_g,
            photo_url=body.photo_url,
        )
        return _to_response(await use_case.execute(dto))
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/{baby_id}/export")
async def export_baby_data(
    baby_id: UUID,
    db: DbDep,
    user_id: CurrentUserDep,
    fmt: str = Query("json", alias="format", pattern="^(json|csv)$"),
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
) -> Response:
    use_case = ExportBabyDataUseCase(db)
    content_type, content = await use_case.execute(baby_id, start_date, end_date, fmt)
    filename = f"muknoljam_export.{fmt}"
    return Response(
        content=content,
        media_type=content_type,
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
