from typing import Annotated
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth_svc.application.interfaces.caregiver_redeem_client import CaregiverRedeemClient
from app.auth_svc.application.interfaces.email_sender import EmailSender
from app.auth_svc.application.interfaces.terms_checker import TermsChecker
from app.auth_svc.application.use_cases.auth.redeem_invite_code import RedeemInviteCodeUseCase
from app.auth_svc.application.use_cases.auth.request_email_otp import RequestEmailOtpUseCase
from app.auth_svc.application.use_cases.auth.verify_email_otp import VerifyEmailOtpUseCase
from app.auth_svc.application.use_cases.auth.withdraw_account import WithdrawAccountUseCase
from app.auth_svc.application.use_cases.terms.agree_terms import AgreeTermsUseCase
from app.auth_svc.application.use_cases.terms.get_active_terms import GetActiveTermsUseCase
from app.auth_svc.domain.repositories.email_otp_repository import EmailOtpRepository
from app.auth_svc.domain.repositories.terms_repository import TermsRepository
from app.auth_svc.domain.repositories.user_repository import UserRepository
from app.auth_svc.config import settings
from app.auth_svc.infrastructure.auth.jwt_handler import decode_access_token
from app.auth_svc.infrastructure.core_client.caregiver_redeem_client_impl import (
    HttpCaregiverRedeemClient,
)
from app.auth_svc.infrastructure.email.factory import get_email_sender
from app.auth_svc.infrastructure.persistence.database import get_db
from app.auth_svc.infrastructure.persistence.repositories.email_otp_repository_impl import (
    EmailOtpRepositoryImpl,
)
from app.auth_svc.infrastructure.persistence.repositories.terms_repository_impl import TermsRepositoryImpl
from app.auth_svc.infrastructure.persistence.repositories.user_repository_impl import UserRepositoryImpl
from app.auth_svc.infrastructure.terms.terms_checker_impl import TermsAgreementChecker

SessionDep = Annotated[AsyncSession, Depends(get_db)]


# --- repositories ---
def get_email_otp_repo(session: SessionDep) -> EmailOtpRepository:
    return EmailOtpRepositoryImpl(session)


def get_user_repo(session: SessionDep) -> UserRepository:
    return UserRepositoryImpl(session)


def get_terms_repo(session: SessionDep) -> TermsRepository:
    return TermsRepositoryImpl(session)


def get_email_sender_dep() -> EmailSender:
    return get_email_sender()


def get_terms_checker(
    terms_repo: Annotated[TermsRepository, Depends(get_terms_repo)],
) -> TermsChecker:
    return TermsAgreementChecker(terms_repo)


# --- use cases ---
def get_request_email_otp_use_case(
    otp_repo: Annotated[EmailOtpRepository, Depends(get_email_otp_repo)],
    email_sender: Annotated[EmailSender, Depends(get_email_sender_dep)],
) -> RequestEmailOtpUseCase:
    return RequestEmailOtpUseCase(otp_repo, email_sender)


def get_verify_email_otp_use_case(
    otp_repo: Annotated[EmailOtpRepository, Depends(get_email_otp_repo)],
    user_repo: Annotated[UserRepository, Depends(get_user_repo)],
    terms_checker: Annotated[TermsChecker, Depends(get_terms_checker)],
) -> VerifyEmailOtpUseCase:
    return VerifyEmailOtpUseCase(otp_repo, user_repo, terms_checker)


def get_withdraw_account_use_case(
    user_repo: Annotated[UserRepository, Depends(get_user_repo)],
) -> WithdrawAccountUseCase:
    return WithdrawAccountUseCase(user_repo)


def get_caregiver_redeem_client() -> CaregiverRedeemClient:
    return HttpCaregiverRedeemClient(settings.CORE_URL, settings.INTERNAL_API_KEY)


def get_redeem_invite_code_use_case(
    user_repo: Annotated[UserRepository, Depends(get_user_repo)],
    redeem_client: Annotated[CaregiverRedeemClient, Depends(get_caregiver_redeem_client)],
    terms_checker: Annotated[TermsChecker, Depends(get_terms_checker)],
) -> RedeemInviteCodeUseCase:
    return RedeemInviteCodeUseCase(user_repo, redeem_client, terms_checker)


def get_active_terms_use_case(
    terms_repo: Annotated[TermsRepository, Depends(get_terms_repo)],
) -> GetActiveTermsUseCase:
    return GetActiveTermsUseCase(terms_repo)


def get_agree_terms_use_case(
    terms_repo: Annotated[TermsRepository, Depends(get_terms_repo)],
) -> AgreeTermsUseCase:
    return AgreeTermsUseCase(terms_repo)


# --- current user (Bearer JWT) ---
def get_current_user_id(authorization: Annotated[str | None, Header()] = None) -> UUID:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="인증이 필요합니다."
        )
    token = authorization[7:].strip()
    user_id = decode_access_token(token)
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="유효하지 않은 토큰입니다."
        )
    return user_id


CurrentUserDep = Annotated[UUID, Depends(get_current_user_id)]
