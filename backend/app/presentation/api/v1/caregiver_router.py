from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.application.use_cases.caregiver import CreateInviteUseCase, JoinByCodeUseCase
from app.infrastructure.persistence.repositories import CaregiverRepositoryImpl
from app.presentation.dependencies import (
    CurrentUserDep,
    get_caregiver_repo,
    get_create_invite_use_case,
    get_join_by_code_use_case,
)
from app.presentation.schemas.baby_schema import BabyResponse
from app.presentation.schemas.caregiver_schema import (
    CaregiverMemberResponse,
    InviteResponse,
    JoinRequest,
)

router = APIRouter(tags=["caregivers"])


@router.post(
    "/babies/{baby_id}/caregivers/invite",
    response_model=InviteResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_invite(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[CreateInviteUseCase, Depends(get_create_invite_use_case)],
) -> InviteResponse:
    try:
        invite = await use_case.execute(baby_id, user_id)
    except PermissionError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    return InviteResponse(code=invite.code, expires_at=invite.expires_at)


@router.get(
    "/babies/{baby_id}/caregivers",
    response_model=list[CaregiverMemberResponse],
)
async def list_caregivers(
    baby_id: UUID,
    user_id: CurrentUserDep,
    caregiver_repo: Annotated[CaregiverRepositoryImpl, Depends(get_caregiver_repo)],
) -> list[CaregiverMemberResponse]:
    members = await caregiver_repo.list_members(baby_id)
    return [
        CaregiverMemberResponse(user_id=m.user_id, role=m.role, created_at=m.created_at)
        for m in members
    ]


@router.post("/caregivers/join", response_model=BabyResponse)
async def join_by_code(
    body: JoinRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[JoinByCodeUseCase, Depends(get_join_by_code_use_case)],
) -> BabyResponse:
    try:
        result = await use_case.execute(body.code, user_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
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
