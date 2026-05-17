from datetime import datetime, timezone
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Request, status
from passlib.context import CryptContext

from app.application.use_cases.auth import RequestOtpUseCase, VerifyOtpUseCase
from app.application.use_cases.auth.request_otp import OtpRateLimitError
from app.application.use_cases.auth.verify_otp import OtpCodeMismatchError, OtpInvalidError
from app.domain.entities.user import User
from app.infrastructure.auth.jwt_handler import create_access_token
from app.infrastructure.persistence.repositories import UserRepositoryImpl
from app.presentation.dependencies import (
    DbDep,
    get_request_otp_use_case,
    get_user_repo,
    get_verify_otp_use_case,
)
from app.presentation.schemas.auth_schema import (
    LoginRequest,
    OtpRequestRequest,
    OtpVerifyRequest,
    OtpVerifyResponse,
    RegisterRequest,
    TokenResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _hash_password(password: str) -> str:
    return _pwd_context.hash(password)


def _verify_password(plain: str, hashed: str) -> bool:
    return _pwd_context.verify(plain, hashed)


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(
    body: RegisterRequest,
    user_repo: Annotated[UserRepositoryImpl, Depends(get_user_repo)],
) -> TokenResponse:
    existing = await user_repo.get_by_email(body.email)
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    user = User(
        id=uuid4(),
        email=body.email,
        name=body.name,
        created_at=datetime.now(timezone.utc),
    )
    hashed_pw = _hash_password(body.password)
    saved = await user_repo.save_with_password(user, hashed_pw)
    token = create_access_token(saved.id)
    return TokenResponse(access_token=token)


@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    user_repo: Annotated[UserRepositoryImpl, Depends(get_user_repo)],
) -> TokenResponse:
    user = await user_repo.get_by_email(body.email)
    hashed_pw = await user_repo.get_hashed_password(body.email)
    if user is None or hashed_pw is None or not _verify_password(body.password, hashed_pw):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    token = create_access_token(user.id)
    return TokenResponse(access_token=token)


# ── OTP (핸드폰 인증) ──────────────────────────────────────────────

@router.post("/otp/request", status_code=status.HTTP_204_NO_CONTENT)
async def request_otp(
    body: OtpRequestRequest,
    request: Request,
    use_case: Annotated[RequestOtpUseCase, Depends(get_request_otp_use_case)],
) -> None:
    ip = request.client.host if request.client else None
    try:
        await use_case.execute(body.phone, ip)
    except OtpRateLimitError as e:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=str(e))
    return None


@router.post("/otp/verify", response_model=OtpVerifyResponse)
async def verify_otp(
    body: OtpVerifyRequest,
    use_case: Annotated[VerifyOtpUseCase, Depends(get_verify_otp_use_case)],
) -> OtpVerifyResponse:
    try:
        result = await use_case.execute(body.phone, body.code)
    except OtpCodeMismatchError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except OtpInvalidError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    return OtpVerifyResponse(
        access_token=result.access_token,
        user_id=result.user_id,
        baby_id=result.baby_id,
        is_new_user=result.is_new_user,
    )
