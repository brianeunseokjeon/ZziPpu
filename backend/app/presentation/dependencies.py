from typing import Annotated
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

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
)
from app.infrastructure.ai.claude_service import ClaudeService
from app.infrastructure.auth.jwt_handler import decode_access_token
from app.application.use_cases.baby import RegisterBabyUseCase, GetBabyProfileUseCase
from app.application.use_cases.feeding import (
    CreateFeedingUseCase,
    GetFeedingsUseCase,
    DeleteFeedingUseCase,
)
from app.application.use_cases.diaper import CreateDiaperRecordUseCase, GetDiaperRecordsUseCase
from app.application.use_cases.sleep import StartSleepUseCase, EndSleepUseCase, GetSleepRecordsUseCase
from app.application.use_cases.play import CreatePlayRecordUseCase, GetPlayRecordsUseCase
from app.application.use_cases.dashboard import GetDailySummaryUseCase
from app.application.use_cases.ai import (
    GenerateDailyReviewUseCase,
    ChatWithPediatricianUseCase,
    SaveChatInfoUseCase,
)

security = HTTPBearer()

DbDep = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user_id(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
) -> UUID:
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


def get_create_play_use_case(
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
) -> CreatePlayRecordUseCase:
    return CreatePlayRecordUseCase(play_repo)


def get_get_plays_use_case(
    play_repo: Annotated[PlayRepositoryImpl, Depends(get_play_repo)],
) -> GetPlayRecordsUseCase:
    return GetPlayRecordsUseCase(play_repo)


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
