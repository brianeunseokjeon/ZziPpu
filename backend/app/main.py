from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import date, datetime, timedelta, timezone
from uuid import UUID, uuid4

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.config import settings
from app.domain.guidelines.vaccination_schedule import VACCINATION_SCHEDULE
from app.infrastructure.persistence.database import AsyncSessionFactory, engine
from app.infrastructure.persistence.models import (  # noqa: F401 — ensure all models are registered
    AIReviewModel,
    BabyModel,
    ChatConversationModel,
    ChatMessageModel,
    DiaperModel,
    FeedingModel,
    GrowthModel,
    PlayModel,
    SavedInfoModel,
    SleepModel,
    UserModel,
    VaccinationModel,
)  # noqa: F401 — UserModel 은 비활성(불투명 user_id). OTP/SMS 는 auth-service 로 이관됨.
from app.infrastructure.persistence.models.base import Base
from app.presentation.api.internal_router import router as internal_router
from app.presentation.api.v1.router import v1_router
from app.presentation.middleware.error_handler import ErrorHandlerMiddleware

DEV_USER_ID = UUID("00000000-0000-0000-0000-000000000001")
DEV_BABY_ID = UUID("00000000-0000-0000-0000-000000000002")


async def _seed_dev_data() -> None:
    """
    DEV_MODE에서만 호출.

    - dev baby가 없으면 생성 + 예방접종 일정 시드
    - 이미 있어도 미접종 예방접종 일정은 현재 `VACCINATION_SCHEDULE` 기준으로 항상 동기화
      (스케줄 정의가 바뀌어도 다음 부팅에 자동 반영. 접종 완료한 항목은 보존.)
    """
    async with AsyncSessionFactory() as session:
        result = await session.execute(select(BabyModel).where(BabyModel.id == DEV_BABY_ID))
        baby = result.scalar_one_or_none()
        now = datetime.now(timezone.utc)

        if baby is None:
            birth_date = date(2025, 4, 13)
            baby = BabyModel(
                id=DEV_BABY_ID,
                user_id=DEV_USER_ID,
                name="우리 아기",
                birth_date=birth_date,
                gender="male",
                birth_weight_g=3200,
                created_at=now,
            )
            session.add(baby)
            await session.flush()
        else:
            birth_date = baby.birth_date

        # 미접종 항목 동기화: 현재 일정과 다른 미접종 기록은 모두 지우고 재생성
        existing = await session.execute(
            select(VaccinationModel).where(VaccinationModel.baby_id == DEV_BABY_ID)
        )
        administered_keys: set[tuple[str, int]] = set()
        for v in existing.scalars():
            if v.administered_date is not None:
                administered_keys.add((v.vaccine_name, v.dose_number))
            else:
                await session.delete(v)
        await session.flush()

        for entry in VACCINATION_SCHEDULE:
            key = (entry["name"], entry["dose"])
            if key in administered_keys:
                continue
            scheduled = birth_date + timedelta(days=entry["offset_days"])
            session.add(VaccinationModel(
                id=uuid4(),
                baby_id=DEV_BABY_ID,
                vaccine_name=entry["name"],
                dose_number=entry["dose"],
                scheduled_date=scheduled,
                administered_date=None,
                hospital_name=None,
                memo=None,
                created_at=now,
            ))

        await session.commit()


async def _migrate_sqlite() -> None:
    """
    SQLite의 `create_all`은 기존 테이블에 컬럼을 추가하지 않으므로
    수동 ALTER TABLE로 누락 컬럼을 보강한다.

    운영 PostgreSQL 전환 시 Alembic으로 교체.
    """
    from sqlalchemy import text

    if not settings.DATABASE_URL.startswith("sqlite"):
        return

    async with engine.begin() as conn:
        # users.phone (Phase 6.B)
        result = await conn.execute(text("PRAGMA table_info(users)"))
        existing_cols = {row[1] for row in result}
        if "phone" not in existing_cols:
            await conn.execute(text("ALTER TABLE users ADD COLUMN phone VARCHAR(32)"))
            await conn.execute(
                text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_phone ON users(phone)")
            )


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await _migrate_sqlite()
    if settings.DEV_MODE:
        await _seed_dev_data()
    yield
    await engine.dispose()


app = FastAPI(
    title="먹놀잠 API",
    description="신생아 육아 기록 서비스 API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(ErrorHandlerMiddleware)

app.include_router(v1_router)
app.include_router(internal_router)


@app.get("/health")
async def health_check() -> dict:
    return {"status": "ok"}
