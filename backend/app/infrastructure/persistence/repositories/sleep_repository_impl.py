from datetime import date
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.sleep_record import SleepRecord
from app.domain.repositories.sleep_repository import SleepRepository
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

    def _to_model(self, entity: SleepRecord) -> SleepModel:
        return SleepModel(
            id=entity.id,
            baby_id=entity.baby_id,
            started_at=entity.started_at,
            ended_at=entity.ended_at,
            memo=entity.memo,
            created_at=entity.created_at,
        )

    async def get(self, id: UUID) -> SleepRecord | None:
        result = await self._session.get(SleepModel, id)
        return self._to_entity(result) if result else None

    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[SleepRecord]:
        stmt = (
            select(SleepModel)
            .where(
                SleepModel.baby_id == baby_id,
                func.date(SleepModel.started_at, '+9 hours') == target_date,
            )
            .order_by(SleepModel.started_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def get_active(self, baby_id: UUID) -> SleepRecord | None:
        stmt = (
            select(SleepModel)
            .where(SleepModel.baby_id == baby_id, SleepModel.ended_at.is_(None))
            .order_by(SleepModel.started_at.desc())
            .limit(1)
        )
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def save(self, record: SleepRecord) -> SleepRecord:
        model = self._to_model(record)
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def update(self, record: SleepRecord) -> SleepRecord:
        model = await self._session.get(SleepModel, record.id)
        if model is None:
            raise ValueError(f"SleepRecord {record.id} not found")
        model.started_at = record.started_at
        model.ended_at = record.ended_at
        model.memo = record.memo
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(SleepModel, id)
        if model:
            await self._session.delete(model)
            await self._session.flush()
