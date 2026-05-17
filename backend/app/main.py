from contextlib import asynccontextmanager
from collections.abc import AsyncIterator
from datetime import date, datetime, timezone, timedelta
from uuid import UUID, uuid4

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.config import settings
from app.infrastructure.persistence.database import engine, AsyncSessionFactory
from app.infrastructure.persistence.models.base import Base
from app.infrastructure.persistence.models import (  # noqa: F401 — ensure all models are registered
    UserModel,
    BabyModel,
    FeedingModel,
    DiaperModel,
    SleepModel,
    PlayModel,
    AIReviewModel,
    ChatConversationModel,
    ChatMessageModel,
    SavedInfoModel,
    GrowthModel,
    VaccinationModel,
)
from app.domain.guidelines.vaccination_schedule import VACCINATION_SCHEDULE
from app.presentation.api.v1.router import v1_router
from app.presentation.middleware.error_handler import ErrorHandlerMiddleware

DEV_USER_ID = UUID("00000000-0000-0000-0000-000000000001")
DEV_BABY_ID = UUID("00000000-0000-0000-0000-000000000002")


async def _seed_dev_data() -> None:
    async with AsyncSessionFactory() as session:
        result = await session.execute(select(BabyModel).where(BabyModel.id == DEV_BABY_ID))
        if result.scalar_one_or_none() is not None:
            return

        birth_date = date(2025, 4, 13)
        baby = BabyModel(
            id=DEV_BABY_ID,
            user_id=DEV_USER_ID,
            name="우리 아기",
            birth_date=birth_date,
            gender="male",
            birth_weight_g=3200,
            created_at=datetime.now(timezone.utc),
        )
        session.add(baby)

        now = datetime.now(timezone.utc)
        for entry in VACCINATION_SCHEDULE:
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


@app.get("/health")
async def health_check() -> dict:
    return {"status": "ok"}
