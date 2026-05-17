from typing import Annotated, Optional
from uuid import UUID

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.infrastructure.persistence.database import get_db
from app.infrastructure.persistence.repositories import (
    BabyRepositoryImpl,
    FeedingRepositoryImpl,
    DiaperRepositoryImpl,
    SleepRepositoryImpl,
    PlayRepositoryImpl,
    AIReviewRepositoryImpl,
    ChatRepositoryImpl,
    SavedInfoRepositoryImpl,
    UserRepositoryImpl,
    GrowthRepositoryImpl,
    VaccinationRepositoryImpl,
    OtpRepositoryImpl,
)
from app.infrastructure.sms import get_sms_service
from app.application.interfaces.sms_service import SmsService
from app.application.use_cases.auth import RequestOtpUseCase, VerifyOtpUseCase
from app.infrastructure.ai.claude_service import ClaudeService
from app.infrastructure.auth.jwt_handler import decode_access_token
from app.application.use_cases.baby import RegisterBabyUseCase, GetBabyProfileUseCase, UpdateBabyUseCase
from app.application.use_cases.feeding import (
    CreateFeedingUseCase,
    GetFeedingsUseCase,
    DeleteFeedingUseCase,
)
from app.application.use_cases.diaper import (
    CreateDiaperRecordUseCase,
    GetDiaperRecordsUseCase,
    DeleteDiaperUseCase,
)
from app.application.use_cases.sleep import (
    StartSleepUseCase,
    EndSleepUseCase,
    GetSleepRecordsUseCase,
    DeleteSleepUseCase,
)
from app.application.use_cases.play import (
    CreatePlayRecordUseCase,
    GetPlayRecordsUseCase,
    DeletePlayUseCase,
)
from app.application.use_cases.dashboard import GetDailySummaryUseCase
from app.application.use_cases.ai import (
    GenerateDailyReviewUseCase,
    ChatWithPediatricianUseCase,
    SaveChatInfoUseCase,
)
from app.application.use_cases.growth import (
    CreateGrowthRecordUseCase,
    GetGrowthRecordsUseCase,
    DeleteGrowthRecordUseCase,
)
from app.application.use_cases.vaccination import (
    GetVaccinationsUseCase,
    MarkAdministeredUseCase,
)

DEV_USER_ID = UUID("00000000-0000-0000-0000-000000000001")

security = HTTPBearer(auto_error=False)

DbDep = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user_id(
    credentials: Annotated[Optional[HTTPAuthorizationCredentials], Depends(security)],
) -> UUID:
    if settings.DEV_MODE:
        return DEV_USER_ID
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = credentials.credentials
    user_id = decode_access_token(token)
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user_id


CurrentUserDep = Annotated[UUID, Depends(get_current_user_id)]


def get_baby_repo(db: DbDep) -> BabyRepositoryImpl:
    return BabyRepositoryImpl(db)


def get_feeding_repo(db: DbDep) -> FeedingRepositoryImpl:
    return FeedingRepositoryImpl(db)


def get_diaper_repo(db: DbDep) -> DiaperRepositoryImpl:
    return DiaperRepositoryImpl(db)


def get_sleep_repo(db: DbDep) -> SleepRepositoryImpl:
    return SleepRepositoryImpl(db)


def get_play_repo(db: DbDep) -> PlayRepositoryImpl:
    return PlayRepositoryImpl(db)


def get_ai_review_repo(db: DbDep) -> AIReviewRepositoryImpl:
    return AIReviewRepositoryImpl(db)


def get_chat_repo(db: DbDep) -> ChatRepositoryImpl:
    return ChatRepositoryImpl(db)


def get_saved_info_repo(db: DbDep) -> SavedInfoRepositoryImpl:
    return SavedInfoRepositoryImpl(db)


def get_user_repo(db: DbDep) -> UserRepositoryImpl:
    return UserRepositoryImpl(db)


def get_vaccination_repo(db: DbDep) -> VaccinationRepositoryImpl:
    return VaccinationRepositoryImpl(db)


def get_claude_service() -> ClaudeService:
    return ClaudeService()


def get_register_baby_use_case(
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
) -> RegisterBabyUseCase:
    return RegisterBabyUseCase(baby_repo)


def get_baby_profile_use_case(
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
) -> GetBabyProfileUseCase:
    return GetBabyProfileUseCase(baby_repo)


def get_update_baby_use_case(
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
    vaccination_repo: Annotated[VaccinationRepositoryImpl, Depends(get_vaccination_repo)],
) -> UpdateBabyUseCase:
    return UpdateBabyUseCase(baby_repo, vaccination_repo)


def get_create_feeding_use_case(
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
) -> CreateFeedingUseCase:
    return CreateFeedingUseCase(feeding_repo)


def get_get_feedings_use_case(
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
) -> GetFeedingsUseCase:
    return GetFeedingsUseCase(feeding_repo)


def get_delete_feeding_use_case(
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
) -> DeleteFeedingUseCase:
    return DeleteFeedingUseCase(feeding_repo)


def get_create_diaper_use_case(
    diaper_repo: Annotated[DiaperRepositoryImpl, Depends(get_diaper_repo)],
) -> CreateDiaperRecordUseCase:
    return CreateDiaperRecordUseCase(diaper_repo)


def get_get_diapers_use_case(
    diaper_repo: Annotated[DiaperRepositoryImpl, Depends(get_diaper_repo)],
) -> GetDiaperRecordsUseCase:
    return GetDiaperRecordsUseCase(diaper_repo)


def get_delete_diaper_use_case(
    diaper_repo: Annotated[DiaperRepositoryImpl, Depends(get_diaper_repo)],
) -> DeleteDiaperUseCase:
    return DeleteDiaperUseCase(diaper_repo)


def get_start_sleep_use_case(
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
) -> StartSleepUseCase:
    return StartSleepUseCase(sleep_repo)


def get_end_sleep_use_case(
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
) -> EndSleepUseCase:
    return EndSleepUseCase(sleep_repo)


def get_get_sleeps_use_case(
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
) -> GetSleepRecordsUseCase:
    return GetSleepRecordsUseCase(sleep_repo)


def get_delete_sleep_use_case(
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
) -> DeleteSleepUseCase:
    return DeleteSleepUseCase(sleep_repo)


def get_create_play_use_case(
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
) -> CreatePlayRecordUseCase:
    return CreatePlayRecordUseCase(play_repo)


def get_get_plays_use_case(
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
) -> GetPlayRecordsUseCase:
    return GetPlayRecordsUseCase(play_repo)


def get_delete_play_use_case(
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
) -> DeletePlayUseCase:
    return DeletePlayUseCase(play_repo)


def get_daily_summary_use_case(
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
    diaper_repo: Annotated[DiaperRepositoryImpl, Depends(get_diaper_repo)],
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
) -> GetDailySummaryUseCase:
    return GetDailySummaryUseCase(feeding_repo, sleep_repo, diaper_repo, play_repo)


def get_generate_review_use_case(
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
    diaper_repo: Annotated[DiaperRepositoryImpl, Depends(get_diaper_repo)],
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
    ai_review_repo: Annotated[AIReviewRepositoryImpl, Depends(get_ai_review_repo)],
    ai_service: Annotated[ClaudeService, Depends(get_claude_service)],
) -> GenerateDailyReviewUseCase:
    return GenerateDailyReviewUseCase(
        baby_repo, feeding_repo, sleep_repo, diaper_repo, play_repo, ai_review_repo, ai_service
    )


def get_chat_use_case(
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
    chat_repo: Annotated[ChatRepositoryImpl, Depends(get_chat_repo)],
    ai_service: Annotated[ClaudeService, Depends(get_claude_service)],
) -> ChatWithPediatricianUseCase:
    return ChatWithPediatricianUseCase(baby_repo, chat_repo, ai_service)


def get_save_info_use_case(
    saved_info_repo: Annotated[SavedInfoRepositoryImpl, Depends(get_saved_info_repo)],
) -> SaveChatInfoUseCase:
    return SaveChatInfoUseCase(saved_info_repo)


def get_growth_repo(db: DbDep) -> GrowthRepositoryImpl:
    return GrowthRepositoryImpl(db)


def get_create_growth_use_case(
    growth_repo: Annotated[GrowthRepositoryImpl, Depends(get_growth_repo)],
) -> CreateGrowthRecordUseCase:
    return CreateGrowthRecordUseCase(growth_repo)


def get_get_growth_records_use_case(
    growth_repo: Annotated[GrowthRepositoryImpl, Depends(get_growth_repo)],
) -> GetGrowthRecordsUseCase:
    return GetGrowthRecordsUseCase(growth_repo)


def get_delete_growth_use_case(
    growth_repo: Annotated[GrowthRepositoryImpl, Depends(get_growth_repo)],
) -> DeleteGrowthRecordUseCase:
    return DeleteGrowthRecordUseCase(growth_repo)


def get_vaccinations_use_case(
    vaccination_repo: Annotated[VaccinationRepositoryImpl, Depends(get_vaccination_repo)],
) -> GetVaccinationsUseCase:
    return GetVaccinationsUseCase(vaccination_repo)


def get_mark_administered_use_case(
    vaccination_repo: Annotated[VaccinationRepositoryImpl, Depends(get_vaccination_repo)],
) -> MarkAdministeredUseCase:
    return MarkAdministeredUseCase(vaccination_repo)


# ── OTP / SMS ──────────────────────────────────────────────────────

def get_otp_repo(db: DbDep) -> OtpRepositoryImpl:
    return OtpRepositoryImpl(db)


def get_sms_service_dep() -> SmsService:
    return get_sms_service()


def get_request_otp_use_case(
    otp_repo: Annotated[OtpRepositoryImpl, Depends(get_otp_repo)],
    sms: Annotated[SmsService, Depends(get_sms_service_dep)],
) -> RequestOtpUseCase:
    return RequestOtpUseCase(otp_repo, sms)


def get_verify_otp_use_case(
    otp_repo: Annotated[OtpRepositoryImpl, Depends(get_otp_repo)],
    user_repo: Annotated[UserRepositoryImpl, Depends(get_user_repo)],
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
) -> VerifyOtpUseCase:
    return VerifyOtpUseCase(otp_repo, user_repo, baby_repo)
