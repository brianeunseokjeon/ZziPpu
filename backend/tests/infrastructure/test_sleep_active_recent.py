"""수면 활성 세션 recent-only + 종료(update) 경로 회귀 테스트.

버그: 로그인 시 오래된 미종료 수면(과거 테스트 잔재)이 영원히 활성으로 뜨고,
종료가 실패한다고 보고됨. 아래 테스트로 다음을 고정한다.

- get_active 는 24h 이내 시작한 미종료 수면만 반환한다(오래된 것은 None).
- 오래된 미종료 수면도 end(update)는 정상 동작한다(하위호환·방어).
- 정상 흐름(start → active → end)이 깨지지 않는다.
"""

from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.application.dto.sleep_dto import EndSleepDTO, StartSleepDTO
from app.application.use_cases.sleep import (
    EndSleepUseCase,
    GetSleepRecordsUseCase,
    StartSleepUseCase,
)
from app.infrastructure.persistence.models.base import Base
from app.infrastructure.persistence.models.sleep_model import SleepModel  # noqa: F401 (register)
from app.infrastructure.persistence.repositories.sleep_repository_impl import SleepRepositoryImpl


@pytest_asyncio.fixture
async def session() -> AsyncSession:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with factory() as s:
        yield s
    await engine.dispose()


@pytest.mark.asyncio
async def test_start_active_end_happy_path(session: AsyncSession) -> None:
    repo = SleepRepositoryImpl(session)
    start, end, get = (
        StartSleepUseCase(repo),
        EndSleepUseCase(repo),
        GetSleepRecordsUseCase(repo),
    )
    baby = uuid4()

    started = await start.execute(
        StartSleepDTO(baby_id=baby, started_at=datetime.now(timezone.utc))
    )
    await session.commit()

    active = await get.get_active(baby)
    assert active is not None and active.id == started.id

    ended = await end.execute(
        EndSleepDTO(sleep_id=started.id, ended_at=datetime.now(timezone.utc))
    )
    await session.commit()
    assert ended.ended_at is not None
    assert ended.duration_minutes is not None

    assert await get.get_active(baby) is None


@pytest.mark.asyncio
async def test_stale_unended_not_active_but_endable(session: AsyncSession) -> None:
    repo = SleepRepositoryImpl(session)
    start, end, get = (
        StartSleepUseCase(repo),
        EndSleepUseCase(repo),
        GetSleepRecordsUseCase(repo),
    )
    baby = uuid4()

    # 3일 전 시작한 미종료 수면 (과거 테스트 잔재 시나리오)
    stale = await start.execute(
        StartSleepDTO(
            baby_id=baby,
            started_at=datetime.now(timezone.utc) - timedelta(days=3),
        )
    )
    await session.commit()

    # 활성으로 뜨지 않아야 함 (phantom 배너 방지)
    assert await get.get_active(baby) is None

    # 그럼에도 종료(update)는 성공해야 함 (하위호환)
    ended = await end.execute(
        EndSleepDTO(sleep_id=stale.id, ended_at=datetime.now(timezone.utc))
    )
    await session.commit()
    assert ended.ended_at is not None
