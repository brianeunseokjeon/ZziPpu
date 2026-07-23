from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import date, datetime, timedelta, timezone
from uuid import UUID, uuid4

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select, text

# ── auth_svc (통합) ──────────────────────────────────────────────────────────
from app.auth_svc.config import settings as auth_settings
from app.auth_svc.infrastructure.persistence.database import (
    AsyncSessionFactory as AuthAsyncSessionFactory,
)
from app.auth_svc.infrastructure.persistence.database import (
    engine as auth_engine,
)
from app.auth_svc.infrastructure.persistence.models import (  # noqa: F401 — register auth models
    EmailOtpModel,
    TermModel,
    TermsAgreementModel,
)
from app.auth_svc.infrastructure.persistence.models.base import Base as AuthBase
from app.auth_svc.infrastructure.persistence.repositories.terms_repository_impl import (
    TermsRepositoryImpl as AuthTermsRepositoryImpl,
)
from app.auth_svc.infrastructure.terms.seed import seed_terms
from app.auth_svc.presentation.api.v1.router import v1_router as auth_v1_router
from app.config import settings
from app.domain.guidelines.vaccination_schedule import VACCINATION_SCHEDULE
from app.infrastructure.persistence.database import AsyncSessionFactory, engine
from app.infrastructure.persistence.models import (  # noqa: F401 — ensure all models are registered
    AIReviewModel,
    BabyModel,
    CareLogModel,
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
                updated_at=now,
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
                updated_at=now,
            ))

        await session.commit()


# 오프라인 동기화 메타 컬럼을 추가할 레코드 테이블 (SyncMixin 적용 대상)
_SYNC_TABLES = (
    "feedings",
    "sleep_records",
    "diaper_records",
    "play_records",
    "growth_records",
    "care_logs",
    "vaccinations",
    "babies",
)


async def _existing_columns(conn, table: str, is_sqlite: bool) -> set[str]:
    from sqlalchemy import text

    if is_sqlite:
        result = await conn.execute(text(f"PRAGMA table_info({table})"))
        return {row[1] for row in result}
    result = await conn.execute(
        text(
            "SELECT column_name FROM information_schema.columns "
            "WHERE table_name = :t"
        ),
        {"t": table},
    )
    return {row[0] for row in result}


async def _migrate_sqlite() -> None:
    """
    `create_all`은 기존 테이블에 컬럼을 추가하지 않으므로 수동 ALTER TABLE로
    누락 컬럼을 보강한다. SQLite(로컬)·PostgreSQL(운영 Neon) 양쪽에서 안전하게 동작.

    운영 PostgreSQL의 본격 스키마 관리는 향후 Alembic으로 교체.
    """
    from sqlalchemy import text

    is_sqlite = settings.DATABASE_URL.startswith("sqlite")

    async with engine.begin() as conn:
        # ── users.phone (Phase 6.B) — SQLite 전용 ─────────────────────────
        if is_sqlite:
            existing_cols = await _existing_columns(conn, "users", is_sqlite=True)
            if "phone" not in existing_cols:
                await conn.execute(text("ALTER TABLE users ADD COLUMN phone VARCHAR(32)"))
                await conn.execute(
                    text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_phone ON users(phone)")
                )

        # ── 오프라인 동기화 메타 컬럼 (updated_at / deleted_at) ───────────
        # 두 컬럼을 nullable 로 추가 → 기존 행 updated_at = created_at 백필 →
        # since 필터 성능용 인덱스 생성. (기존 프로덕션 데이터 무해.)
        dt_type = "TIMESTAMP"
        for table in _SYNC_TABLES:
            cols = await _existing_columns(conn, table, is_sqlite)
            if not cols:
                # 테이블 자체가 아직 없음(create_all 이 방금 새 컬럼 포함해 생성) → skip
                continue
            if "updated_at" not in cols:
                await conn.execute(
                    text(f"ALTER TABLE {table} ADD COLUMN updated_at {dt_type}")
                )
                await conn.execute(
                    text(
                        f"UPDATE {table} SET updated_at = created_at "
                        "WHERE updated_at IS NULL"
                    )
                )
                await conn.execute(
                    text(
                        f"CREATE INDEX IF NOT EXISTS ix_{table}_updated_at "
                        f"ON {table}(updated_at)"
                    )
                )
            if "deleted_at" not in cols:
                await conn.execute(
                    text(f"ALTER TABLE {table} ADD COLUMN deleted_at {dt_type}")
                )

        # ── diaper_records.amount (기저귀 양: little|normal|lot) ───────────
        # nullable 컬럼만 추가(파괴적 변경 없음). 하위호환: 없어도 기존 동작.
        # 멱등 — 이미 있으면 skip. 실패해도 앱 기동은 막지 않음(로그만).
        try:
            diaper_cols = await _existing_columns(conn, "diaper_records", is_sqlite)
            if diaper_cols and "amount" not in diaper_cols:
                if is_sqlite:
                    await conn.execute(
                        text("ALTER TABLE diaper_records ADD COLUMN amount VARCHAR(20)")
                    )
                else:
                    # PostgreSQL(Neon): IF NOT EXISTS 로 멱등 보장
                    await conn.execute(
                        text(
                            "ALTER TABLE diaper_records "
                            "ADD COLUMN IF NOT EXISTS amount VARCHAR(20)"
                        )
                    )
        except Exception:  # noqa: BLE001 — 마이그레이션 실패가 기동을 막지 않도록
            import logging

            logging.getLogger(__name__).warning(
                "diaper_records.amount 마이그레이션 실패(무시하고 기동 계속)",
                exc_info=True,
            )

        # ── feedings.did_vomit (먹고 토했는지 여부) ──────────────────────────
        # NOT NULL DEFAULT FALSE/0. 기존 행은 server_default 로 백필됨.
        # 멱등 — 이미 있으면 skip. 실패해도 앱 기동은 막지 않음(로그만).
        try:
            feeding_cols = await _existing_columns(conn, "feedings", is_sqlite)
            if feeding_cols and "did_vomit" not in feeding_cols:
                if is_sqlite:
                    await conn.execute(
                        text("ALTER TABLE feedings ADD COLUMN did_vomit BOOLEAN NOT NULL DEFAULT 0")
                    )
                else:
                    # PostgreSQL(Neon): IF NOT EXISTS 로 멱등 보장
                    await conn.execute(
                        text(
                            "ALTER TABLE feedings "
                            "ADD COLUMN IF NOT EXISTS did_vomit BOOLEAN NOT NULL DEFAULT FALSE"
                        )
                    )
        except Exception:  # noqa: BLE001 — 마이그레이션 실패가 기동을 막지 않도록
            import logging

            logging.getLogger(__name__).warning(
                "feedings.did_vomit 마이그레이션 실패(무시하고 기동 계속)",
                exc_info=True,
            )

        # ── babies 신규 프로필 컬럼 (전부 nullable · 하위호환 · 멱등) ─────────
        # 측정치 3개(키/두위/흉위)=DOUBLE PRECISION(PG)/REAL(SQLite),
        # blood_type=VARCHAR(4), rh_factor=VARCHAR(10), birth_time=VARCHAR(5).
        # 파괴적 변경 없음. 실패해도 앱 기동은 막지 않음(로그만).
        try:
            baby_cols = await _existing_columns(conn, "babies", is_sqlite)
            if baby_cols:  # 테이블이 이미 존재할 때만(create_all 이 새로 만든 경우 skip)
                float_type = "REAL" if is_sqlite else "DOUBLE PRECISION"
                new_baby_cols = (
                    ("birth_height_cm", float_type),
                    ("birth_head_circumference_cm", float_type),
                    ("birth_chest_circumference_cm", float_type),
                    ("blood_type", "VARCHAR(4)"),
                    ("rh_factor", "VARCHAR(10)"),
                    ("birth_time", "VARCHAR(5)"),
                )
                for col_name, col_type in new_baby_cols:
                    if col_name in baby_cols:
                        continue  # 멱등 — 이미 있으면 skip
                    if is_sqlite:
                        await conn.execute(
                            text(f"ALTER TABLE babies ADD COLUMN {col_name} {col_type}")
                        )
                    else:
                        # PostgreSQL(Neon/Render): IF NOT EXISTS 로 멱등 보장
                        await conn.execute(
                            text(
                                f"ALTER TABLE babies "
                                f"ADD COLUMN IF NOT EXISTS {col_name} {col_type}"
                            )
                        )
        except Exception:  # noqa: BLE001 — 마이그레이션 실패가 기동을 막지 않도록
            import logging

            logging.getLogger(__name__).warning(
                "babies 신규 컬럼 마이그레이션 실패(무시하고 기동 계속)",
                exc_info=True,
            )

        # ── growth_records.temperature_c (체온 섭씨, nullable REAL) ──────────
        # 멱등 — 이미 있으면 skip. 실패해도 앱 기동은 막지 않음(로그만).
        try:
            growth_cols = await _existing_columns(conn, "growth_records", is_sqlite)
            if growth_cols and "temperature_c" not in growth_cols:
                if is_sqlite:
                    await conn.execute(
                        text("ALTER TABLE growth_records ADD COLUMN temperature_c REAL")
                    )
                else:
                    await conn.execute(
                        text(
                            "ALTER TABLE growth_records "
                            "ADD COLUMN IF NOT EXISTS temperature_c DOUBLE PRECISION"
                        )
                    )
        except Exception:  # noqa: BLE001 — 마이그레이션 실패가 기동을 막지 않도록
            import logging

            logging.getLogger(__name__).warning(
                "growth_records.temperature_c 마이그레이션 실패(무시하고 기동 계속)",
                exc_info=True,
            )


_WITHDRAW_GRACE_DAYS = 30


async def _purge_withdrawn_accounts() -> None:
    """유예(30일) 만료된 탈퇴 계정 완전삭제: 계정 + 소유 아기 + 전 기록 + 양육자/약관.
    기동 시 1회 실행. 크로스-DB(main 기록 / auth 계정)를 각 세션으로 처리한다.
    NOTE: 대량 삭제 — 운영 반영 전 스테이징에서 검증 권장.
    """
    from datetime import datetime, timedelta, timezone

    from sqlalchemy import delete, select

    from app.auth_svc.infrastructure.persistence.models.term_model import (
        TermsAgreementModel,
    )
    from app.auth_svc.infrastructure.persistence.models.user_model import (
        UserModel as AuthUserModel,
    )
    from app.infrastructure.persistence.models.ai_review_model import AIReviewModel
    from app.infrastructure.persistence.models.baby_model import BabyModel
    from app.infrastructure.persistence.models.care_log_model import CareLogModel
    from app.infrastructure.persistence.models.caregiver_model import (
        BabyCaregiverModel,
        CaregiverInviteModel,
    )
    from app.infrastructure.persistence.models.chat_conversation_model import (
        ChatConversationModel,
    )
    from app.infrastructure.persistence.models.chat_message_model import ChatMessageModel
    from app.infrastructure.persistence.models.diaper_model import DiaperModel
    from app.infrastructure.persistence.models.feeding_model import FeedingModel
    from app.infrastructure.persistence.models.growth_model import GrowthModel
    from app.infrastructure.persistence.models.play_model import PlayModel
    from app.infrastructure.persistence.models.saved_info_model import SavedInfoModel
    from app.infrastructure.persistence.models.sleep_model import SleepModel
    from app.infrastructure.persistence.models.vaccination_model import VaccinationModel

    cutoff = datetime.now(timezone.utc) - timedelta(days=_WITHDRAW_GRACE_DAYS)

    # 1) 유예 만료 user_id (auth)
    async with AuthAsyncSessionFactory() as auth_session:
        res = await auth_session.execute(
            select(AuthUserModel.id).where(
                AuthUserModel.deleted_at.is_not(None),
                AuthUserModel.deleted_at < cutoff,
            )
        )
        user_ids = list(res.scalars().all())

    if not user_ids:
        return

    # 2) main: 소유 아기 + 전 기록(baby_id 스코프) + 양육자 링크/초대
    async with AsyncSessionFactory() as session:
        res = await session.execute(
            select(BabyModel.id).where(BabyModel.user_id.in_(user_ids))
        )
        baby_ids = list(res.scalars().all())
        if baby_ids:
            for model in (
                FeedingModel, SleepModel, DiaperModel, PlayModel, CareLogModel,
                GrowthModel, VaccinationModel, ChatConversationModel,
                ChatMessageModel, AIReviewModel, SavedInfoModel,
                BabyCaregiverModel, CaregiverInviteModel,
            ):
                await session.execute(delete(model).where(model.baby_id.in_(baby_ids)))
        # 이 유저가 '추가 양육자'로 들어간 다른 아기의 멤버십도 제거
        await session.execute(
            delete(BabyCaregiverModel).where(BabyCaregiverModel.user_id.in_(user_ids))
        )
        await session.execute(delete(BabyModel).where(BabyModel.user_id.in_(user_ids)))
        await session.commit()

    # 3) auth: 약관동의 + 계정
    async with AuthAsyncSessionFactory() as auth_session:
        await auth_session.execute(
            delete(TermsAgreementModel).where(TermsAgreementModel.user_id.in_(user_ids))
        )
        await auth_session.execute(
            delete(AuthUserModel).where(AuthUserModel.id.in_(user_ids))
        )
        await auth_session.commit()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # ── core DB init ─────────────────────────────────────────────────────────
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await _migrate_sqlite()
    if settings.DEV_MODE:
        await _seed_dev_data()

    # ── auth_svc DB init ─────────────────────────────────────────────────────
    async with auth_engine.begin() as conn:
        await conn.run_sync(AuthBase.metadata.create_all)
        # users.deleted_at (회원탈퇴 소프트삭제) — 기존 테이블 보강(idempotent, sqlite/pg)
        from sqlalchemy import text as _text

        auth_is_sqlite = auth_settings.AUTH_DATABASE_URL.startswith("sqlite")
        _ucols = await _existing_columns(conn, "users", auth_is_sqlite)
        if _ucols and "deleted_at" not in _ucols:
            await conn.execute(_text("ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP"))
    # 약관 seed (마크다운 → terms upsert)
    async with AuthAsyncSessionFactory() as session:
        await seed_terms(AuthTermsRepositoryImpl(session))
        await session.commit()

    # 유예 만료된 탈퇴 계정 완전삭제(기동 시 1회)
    await _purge_withdrawn_accounts()

    yield

    await engine.dispose()
    await auth_engine.dispose()


app = FastAPI(
    title="먹놀잠 API (통합)",
    description="신생아 육아 기록 서비스 API — core + auth 통합 단일 프로세스",
    version="2.0.0",
    lifespan=lifespan,
)

# CORS: core + auth 양쪽 origins 합집합
_cors_origins = list(dict.fromkeys(settings.CORS_ORIGINS + auth_settings.CORS_ORIGINS))
_cors_origin_regex = settings.CORS_ORIGIN_REGEX or auth_settings.CORS_ORIGIN_REGEX

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_origin_regex=_cors_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(ErrorHandlerMiddleware)

app.include_router(v1_router)
app.include_router(internal_router)
app.include_router(auth_v1_router)  # auth: /api/v1/auth/*, /api/v1/auth/terms, /api/v1/auth/code


@app.get("/health")
async def health_check() -> dict:
    # keep-warm 핑 대상. DB를 가볍게 touch(SELECT 1)해서 Render 웹서비스뿐 아니라
    # Neon(5분 유휴 시 컴퓨트 정지)까지 함께 깨워 둔다 — 그래야 첫 실제 쿼리 콜드가 없다.
    # DB가 죽어도 200은 유지(핑 자체가 죽어 keep-warm이 끊기지 않도록). 상태만 바디에 표기.
    db_ok = False
    try:
        async with AsyncSessionFactory() as session:
            await session.execute(text("SELECT 1"))
        db_ok = True
    except Exception:  # noqa: BLE001 — health는 절대 500 내면 안 됨(핑 유지)
        db_ok = False
    return {"status": "ok", "service": "muknoljam-unified", "db": "ok" if db_ok else "down"}
