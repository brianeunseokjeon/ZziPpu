from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, status

from app.application.use_cases.auth.request_email_otp import (
    OtpRateLimitError,
    RequestEmailOtpUseCase,
)
from app.application.use_cases.auth.verify_email_otp import (
    OtpCodeMismatchError,
    OtpInvalidError,
    VerifyEmailOtpUseCase,
)
from app.presentation.dependencies import (
    get_request_email_otp_use_case,
    get_verify_email_otp_use_case,
)
from app.presentation.schemas.auth_schema import (
    EmailOtpRequestRequest,
    EmailOtpVerifyRequest,
    EmailOtpVerifyResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/email/request", status_code=status.HTTP_204_NO_CONTENT)
async def request_email_otp(
    body: EmailOtpRequestRequest,
    request: Request,
    use_case: Annotated[RequestEmailOtpUseCase, Depends(get_request_email_otp_use_case)],
) -> None:
    request_ip = request.client.host if request.client else None
    try:
        await use_case.execute(str(body.email), request_ip)
    except OtpRateLimitError as e:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=str(e))


@router.post("/email/verify", response_model=EmailOtpVerifyResponse)
async def verify_email_otp(
    body: EmailOtpVerifyRequest,
    use_case: Annotated[VerifyEmailOtpUseCase, Depends(get_verify_email_otp_use_case)],
) -> EmailOtpVerifyResponse:
    try:
        result = await use_case.execute(str(body.email), body.code)
    except (OtpInvalidError, OtpCodeMismatchError) as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    return EmailOtpVerifyResponse(
        access_token=result.access_token,
        user_id=result.user_id,
        is_new_user=result.is_new_user,
        terms_required=result.terms_required,
    )
