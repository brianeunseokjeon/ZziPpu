from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.application.use_cases.caregiver import JoinByCodeUseCase
from app.presentation.dependencies import get_join_by_code_use_case, verify_internal_key

# 내부 전용 라우터. 게이트웨이 없이 auth-service 가 X-Internal-Key 로 호출한다.
router = APIRouter(prefix="/internal", tags=["internal"])


class CaregiverRedeemRequest(BaseModel):
    code: str
    user_id: UUID


class CaregiverRedeemResponse(BaseModel):
    baby_id: UUID


@router.post(
    "/caregiver/redeem",
    response_model=CaregiverRedeemResponse,
    dependencies=[Depends(verify_internal_key)],
)
async def redeem_caregiver_code(
    body: CaregiverRedeemRequest,
    use_case: Annotated[JoinByCodeUseCase, Depends(get_join_by_code_use_case)],
) -> CaregiverRedeemResponse:
    """1회용 초대코드를 검증해 baby_caregivers 링크를 만들고 코드를 소비한다.

    user_id 는 auth-service 가 방금 생성한 공동양육자 신원(불투명 UUID).
    코드 무효 시 ValueError → 400 (auth-service 가 user 폐기).
    """
    try:
        result = await use_case.execute(body.code, body.user_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    return CaregiverRedeemResponse(baby_id=result.id)
