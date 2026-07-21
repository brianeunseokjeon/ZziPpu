from typing import Annotated, Optional
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.use_cases.ai import (
    ChatWithPediatricianUseCase,
    DeleteSavedInfoUseCase,
    GenerateDailyReviewUseCase,
    ListSavedInfosUseCase,
    SaveChatInfoUseCase,
)
from app.application.use_cases.baby import (
    GetBabyProfileUseCase,
    RegisterBabyUseCase,
    UpdateBabyUseCase,
)
from app.application.use_cases.caregiver import CreateInviteUseCase, JoinByCodeUseCase
from app.application.use_cases.dashboard import GetDailySummaryUseCase, GetPredictionsUseCase
from app.application.use_cases.diaper import (
    CreateDiaperRecordUseCase,
    DeleteDiaperUseCase,
    GetDiaperRecordsUseCase,
)
from app.application.use_cases.feeding import (
    CreateFeedingUseCase,
    DeleteFeedingUseCase,
    GetFeedingsUseCase,
    UpdateFeedingUseCase,
)
from app.application.use_cases.growth import (
    CreateGrowthRecordUseCase,
    DeleteGrowthRecordUseCase,
    GetGrowthRecordsUseCase,
    UpdateGrowthRecordUseCase,
)
from app.application.use_cases.care_log import (
    CreateCareLogUseCase,
    DeleteCareLogUseCase,
    GetCareLogsUseCase,
    UpdateCareLogUseCase,
)
from app.application.use_cases.play import (
    CreatePlayRecordUseCase,
    DeletePlayUseCase,
    GetPlayRecordsUseCase,
)
from app.application.use_cases.sleep import (
    DeleteSleepUseCase,
    EndSleepUseCase,
    GetSleepRecordsUseCase,
    StartSleepUseCase,
)
from app.application.use_cases.vaccination import (
    GetVaccinationsUseCase,
    MarkAdministeredUseCase,
)
from app.config import settings
from app.infrastructure.ai.claude_service import ClaudeService
from app.infrastructure.auth.jwt_handler import decode_access_token
from app.infrastructure.persistence.database import get_db
from app.infrastructure.persistence.repositories import (
    AIReviewRepositoryImpl,
    BabyRepositoryImpl,
    CareLogRepositoryImpl,
    CaregiverRepositoryImpl,
    ChatRepositoryImpl,
    DiaperRepositoryImpl,
    FeedingRepositoryImpl,
    GrowthRepositoryImpl,
    PlayRepositoryImpl,
    SavedInfoRepositoryImpl,
    SleepRepositoryImpl,
    VaccinationRepositoryImpl,
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


def get_caregiver_repo(db: DbDep) -> CaregiverRepositoryImpl:
    return CaregiverRepositoryImpl(db)


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
    caregiver_repo: Annotated[CaregiverRepositoryImpl, Depends(get_caregiver_repo)],
) -> GetBabyProfileUseCase:
    return GetBabyProfileUseCase(baby_repo, caregiver_repo)


def get_create_invite_use_case(
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
    caregiver_repo: Annotated[CaregiverRepositoryImpl, Depends(get_caregiver_repo)],
) -> CreateInviteUseCase:
    return CreateInviteUseCase(baby_repo, caregiver_repo)


def get_join_by_code_use_case(
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
    caregiver_repo: Annotated[CaregiverRepositoryImpl, Depends(get_caregiver_repo)],
) -> JoinByCodeUseCase:
    return JoinByCodeUseCase(baby_repo, caregiver_repo)


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


def get_update_feeding_use_case(
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
) -> UpdateFeedingUseCase:
    return UpdateFeedingUseCase(feeding_repo)


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


def get_care_log_repo(db: DbDep) -> CareLogRepositoryImpl:
    return CareLogRepositoryImpl(db)


def get_create_care_log_use_case(
    care_log_repo: Annotated[CareLogRepositoryImpl, Depends(get_care_log_repo)],
) -> CreateCareLogUseCase:
    return CreateCareLogUseCase(care_log_repo)


def get_get_care_logs_use_case(
    care_log_repo: Annotated[CareLogRepositoryImpl, Depends(get_care_log_repo)],
) -> GetCareLogsUseCase:
    return GetCareLogsUseCase(care_log_repo)


def get_update_care_log_use_case(
    care_log_repo: Annotated[CareLogRepositoryImpl, Depends(get_care_log_repo)],
) -> UpdateCareLogUseCase:
    return UpdateCareLogUseCase(care_log_repo)


def get_delete_care_log_use_case(
    care_log_repo: Annotated[CareLogRepositoryImpl, Depends(get_care_log_repo)],
) -> DeleteCareLogUseCase:
    return DeleteCareLogUseCase(care_log_repo)


def get_daily_summary_use_case(
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
    diaper_repo: Annotated[DiaperRepositoryImpl, Depends(get_diaper_repo)],
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
) -> GetDailySummaryUseCase:
    return GetDailySummaryUseCase(feeding_repo, sleep_repo, diaper_repo, play_repo)


def get_predictions_use_case(
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
) -> GetPredictionsUseCase:
    return GetPredictionsUseCase(feeding_repo, sleep_repo)


def get_generate_review_use_case(
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
    diaper_repo: Annotated[DiaperRepositoryImpl, Depends(get_diaper_repo)],
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
    ai_review_repo: Annotated[AIReviewRepositoryImpl, Depends(get_ai_review_repo)],
    ai_service: Annotated[ClaudeService, Depends(get_claude_service)],
    care_log_repo: Annotated[CareLogRepositoryImpl, Depends(get_care_log_repo)],
) -> GenerateDailyReviewUseCase:
    return GenerateDailyReviewUseCase(
        baby_repo, feeding_repo, sleep_repo, diaper_repo, play_repo, ai_review_repo, ai_service,
        care_log_repo,
    )


def get_chat_use_case(
    baby_repo: Annotated[BabyRepositoryImpl, Depends(get_baby_repo)],
    chat_repo: Annotated[ChatRepositoryImpl, Depends(get_chat_repo)],
    ai_service: Annotated[ClaudeService, Depends(get_claude_service)],
    feeding_repo: Annotated[FeedingRepositoryImpl, Depends(get_feeding_repo)],
    sleep_repo: Annotated[SleepRepositoryImpl, Depends(get_sleep_repo)],
    diaper_repo: Annotated[DiaperRepositoryImpl, Depends(get_diaper_repo)],
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
    care_log_repo: Annotated[CareLogRepositoryImpl, Depends(get_care_log_repo)],
) -> ChatWithPediatricianUseCase:
    return ChatWithPediatricianUseCase(
        baby_repo, chat_repo, ai_service, feeding_repo, sleep_repo, diaper_repo, play_repo,
        care_log_repo,
    )


def get_save_info_use_case(
    saved_info_repo: Annotated[SavedInfoRepositoryImpl, Depends(get_saved_info_repo)],
) -> SaveChatInfoUseCase:
    return SaveChatInfoUseCase(saved_info_repo)


def get_list_saved_infos_use_case(
    saved_info_repo: Annotated[SavedInfoRepositoryImpl, Depends(get_saved_info_repo)],
) -> ListSavedInfosUseCase:
    return ListSavedInfosUseCase(saved_info_repo)


def get_delete_saved_info_use_case(
    saved_info_repo: Annotated[SavedInfoRepositoryImpl, Depends(get_saved_info_repo)],
) -> DeleteSavedInfoUseCase:
    return DeleteSavedInfoUseCase(saved_info_repo)


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


def get_update_growth_use_case(
    growth_repo: Annotated[GrowthRepositoryImpl, Depends(get_growth_repo)],
) -> UpdateGrowthRecordUseCase:
    return UpdateGrowthRecordUseCase(growth_repo)


def get_vaccinations_use_case(
    vaccination_repo: Annotated[VaccinationRepositoryImpl, Depends(get_vaccination_repo)],
) -> GetVaccinationsUseCase:
    return GetVaccinationsUseCase(vaccination_repo)


def get_mark_administered_use_case(
    vaccination_repo: Annotated[VaccinationRepositoryImpl, Depends(get_vaccination_repo)],
) -> MarkAdministeredUseCase:
    return MarkAdministeredUseCase(vaccination_repo)


# ── 내부 서비스 호출 인증 (auth-service → core) ──────────────────────

def verify_internal_key(
    x_internal_key: Annotated[Optional[str], Header()] = None,
) -> None:
    """auth-service 가 공유 INTERNAL_API_KEY 로 호출하는 내부 엔드포인트 보호."""
    if not x_internal_key or x_internal_key != settings.INTERNAL_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid internal key",
        )
