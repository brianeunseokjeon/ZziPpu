from datetime import datetime, timezone
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from passlib.context import CryptContext

from app.domain.entities.user import User
from app.infrastructure.auth.jwt_handler import create_access_token
from app.infrastructure.persistence.repositories import UserRepositoryImpl
from app.presentation.dependencies import DbDep, get_user_repo
from app.presentation.schemas.auth_schema import LoginRequest, RegisterRequest, TokenResponse

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
