from datetime import date, datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.sleep_record import SleepRecord
from app.domain.repositories.sleep_repository import SleepRepository
from app.infrastructure.persistence.db_date_utils import kst_date_eq
from app.infrastructure.persistence.models.sleep_model import SleepModel


class SleepRepositoryImpl(SleepRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: SleepModel) -> SleepRecord:
        return SleepRecord(
            id=model.id,
            baby_id=model.baby_id,
            started_at=model.started_at,
            ended_at=model.ended_at,
            memo=model.memo,
            created_at=model.created_at,
        )

    def _apply_fields(self, model: SleepModel, entity: SleepRecord) -> None:
        model.baby_id = entity.baby_id
        model.started_at = entity.started_at
        model.ended_at = entity.ended_at
        model.memo = entity.memo

    async def get(self, id: UUID) -> SleepRecord | None:
        result = await self._session.get(SleepModel, id)
        if result is None or result.deleted_at is not None:
            return None
        return self._to_entity(result)

    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[SleepRecord]:
        stmt = (
            select(SleepModel)
            .where(
                SleepModel.baby_id == baby_id,
                SleepModel.deleted_at.is_(None),
                kst_date_eq(SleepModel.started_at, target_date),
            )
            .order_by(SleepModel.started_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    # 미종료 세션을 "활성"으로 인정할 최대 경과(과거 테스트 잔재·종료 누락 배제).
    # 클라(iOS/웹)와 동일하게 24h. started_at 이 이보다 오래되면 활성으로 보지 않는다.
    _ACTIVE_STALE_THRESHOLD = timedelta(hours=24)

    async def get_active(self, baby_id: UUID) -> SleepRecord | None:
        # started_at 은 naive UTC 저장 → 비교 기준도 naive UTC.
        now_naive = datetime.now(timezone.utc).replace(tzinfo=None)
        recent_cutoff = now_naive - self._ACTIVE_STALE_THRESHOLD
        stmt = (
            select(SleepModel)
            .where(
                SleepModel.baby_id == baby_id,
                SleepModel.deleted_at.is_(None),
                SleepModel.ended_at.is_(None),
                SleepModel.started_at >= recent_cutoff,
            )
            .order_by(SleepModel.started_at.desc())
            .limit(1)
        )
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def get_recent(self, baby_id: UUID, limit: int = 12) -> list[SleepRecord]:
        stmt = (
            select(SleepModel)
            .where(
                SleepModel.baby_id == baby_id,
                SleepModel.deleted_at.is_(None),
            )
            .order_by(SleepModel.started_at.desc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, record: SleepRecord) -> SleepRecord:
        now = datetime.now(timezone.utc)
        model = await self._session.get(SleepModel, record.id)
        if model is None:
            model = SleepModel(id=record.id, created_at=record.created_at)
            self._apply_fields(model, record)
            model.deleted_at = None
            model.updated_at = now
            self._session.add(model)
        else:
            self._apply_fields(model, record)
            model.deleted_at = None
            model.updated_at = now
        await self._session.flush()
        return self._to_entity(model)

    async def update(self, record: SleepRecord) -> SleepRecord:
        model = await self._session.get(SleepModel, record.id)
        if model is None or model.deleted_at is not None:
            raise ValueError(f"SleepRecord {record.id} not found")
        self._apply_fields(model, record)
        model.updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(SleepModel, id)
        if model and model.deleted_at is None:
            now = datetime.now(timezone.utc)
            model.deleted_at = now
            model.updated_at = now
            await self._session.flush()
