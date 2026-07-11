from datetime import date, datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.play_record import PlayRecord
from app.domain.repositories.play_repository import PlayRepository
from app.infrastructure.persistence.db_date_utils import kst_date_eq
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

    def _apply_fields(self, model: PlayModel, entity: PlayRecord) -> None:
        model.baby_id = entity.baby_id
        model.play_type = entity.play_type
        model.started_at = entity.started_at
        model.ended_at = entity.ended_at
        model.duration_minutes = entity.duration_minutes
        model.memo = entity.memo

    async def get(self, id: UUID) -> PlayRecord | None:
        result = await self._session.get(PlayModel, id)
        if result is None or result.deleted_at is not None:
            return None
        return self._to_entity(result)

    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[PlayRecord]:
        stmt = (
            select(PlayModel)
            .where(
                PlayModel.baby_id == baby_id,
                PlayModel.deleted_at.is_(None),
                kst_date_eq(PlayModel.started_at, target_date),
            )
            .order_by(PlayModel.started_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, record: PlayRecord) -> PlayRecord:
        now = datetime.now(timezone.utc)
        model = await self._session.get(PlayModel, record.id)
        if model is None:
            model = PlayModel(id=record.id, created_at=record.created_at)
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

    async def update(self, record: PlayRecord) -> PlayRecord:
        model = await self._session.get(PlayModel, record.id)
        if model is None or model.deleted_at is not None:
            raise ValueError(f"PlayRecord {record.id} not found")
        self._apply_fields(model, record)
        model.updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(PlayModel, id)
        if model and model.deleted_at is None:
            now = datetime.now(timezone.utc)
            model.deleted_at = now
            model.updated_at = now
            await self._session.flush()
