from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth_svc.application.interfaces.caregiver_redeem_client import InvalidInviteCodeError
from app.auth_svc.application.use_cases.auth.redeem_invite_code import RedeemInviteCodeUseCase
from app.auth_svc.presentation.dependencies import get_redeem_invite_code_use_case
from app.auth_svc.presentation.schemas.auth_schema import CodeRedeemRequest, CodeRedeemResponse

router = APIRouter(prefix="/auth/code", tags=["auth"])


@router.post("/redeem", response_model=CodeRedeemResponse)
async def redeem_invite_code(
    body: CodeRedeemRequest,
    use_case: Annotated[RedeemInviteCodeUseCase, Depends(get_redeem_invite_code_use_case)],
) -> CodeRedeemResponse:
    try:
        result = await use_case.execute(body.code)
    except InvalidInviteCodeError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    return CodeRedeemResponse(
        access_token=result.access_token,
        user_id=result.user_id,
        baby_id=result.baby_id,
        is_new_user=result.is_new_user,
        terms_required=result.terms_required,
    )
