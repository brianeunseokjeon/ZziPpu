from datetime import date
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.play_record import PlayRecord
from app.domain.repositories.play_repository import PlayRepository
from app.infrastructure.persistence.models.play_model import PlayModel


class PlayRepositoryImpl(PlayRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: PlayModel) -> PlayRecord:
        return PlayRecord(
            id=model.id,
            baby_id=model.baby_id,
            play_type=model.play_type,
            started_at=model.started_at,
            ended_at=model.ended_at,
            duration_minutes=model.duration_minutes,
            memo=model.memo,
            created_at=model.created_at,
        )

    def _to_model(self, entity: PlayRecord) -> PlayModel:
        return PlayModel(
            id=entity.id,
            baby_id=entity.baby_id,
            play_type=entity.play_type,
            started_at=entity.started_at,
            ended_at=entity.ended_at,
            duration_minutes=entity.duration_minutes,
            memo=entity.memo,
            created_at=entity.created_at,
        )

    async def get(self, id: UUID) -> PlayRecord | None:
        result = await self._session.get(PlayModel, id)
        return self._to_entity(result) if result else None

    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[PlayRecord]:
        stmt = (
            select(PlayModel)
            .where(
                PlayModel.baby_id == baby_id,
                func.date(PlayModel.started_at, '+9 hours') == target_date,
            )
            .order_by(PlayModel.started_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, record: PlayRecord) -> PlayRecord:
        model = self._to_model(record)
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def update(self, record: PlayRecord) -> PlayRecord:
        model = await self._session.get(PlayModel, record.id)
        if model is None:
            raise ValueError(f"PlayRecord {record.id} not found")
        model.play_type = record.play_type
        model.started_at = record.started_at
        model.ended_at = record.ended_at
        model.duration_minutes = record.duration_minutes
        model.memo = record.memo
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(PlayModel, id)
        if model:
            await self._session.delete(model)
            await self._session.flush()
