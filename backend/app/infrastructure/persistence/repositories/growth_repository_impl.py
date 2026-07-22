from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.growth_record import GrowthRecord
from app.domain.repositories.growth_repository import GrowthRepository
from app.infrastructure.persistence.models.growth_model import GrowthModel


class GrowthRepositoryImpl(GrowthRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: GrowthModel) -> GrowthRecord:
        return GrowthRecord(
            id=model.id,
            baby_id=model.baby_id,
            recorded_at=model.recorded_at,
            weight_g=model.weight_g,
            height_cm=model.height_cm,
            head_circumference_cm=model.head_circumference_cm,
            temperature_c=model.temperature_c,
            memo=model.memo,
            created_at=model.created_at,
        )

    def _apply_fields(self, model: GrowthModel, entity: GrowthRecord) -> None:
        model.baby_id = entity.baby_id
        model.recorded_at = entity.recorded_at
        model.weight_g = entity.weight_g
        model.height_cm = entity.height_cm
        model.head_circumference_cm = entity.head_circumference_cm
        model.temperature_c = entity.temperature_c
        model.memo = entity.memo

    async def get(self, id: UUID) -> GrowthRecord | None:
        result = await self._session.get(GrowthModel, id)
        if result is None or result.deleted_at is not None:
            return None
        return self._to_entity(result)

    async def get_by_baby_id(self, baby_id: UUID) -> list[GrowthRecord]:
        stmt = (
            select(GrowthModel)
            .where(
                GrowthModel.baby_id == baby_id,
                GrowthModel.deleted_at.is_(None),
            )
            .order_by(GrowthModel.recorded_at.desc())
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, record: GrowthRecord) -> GrowthRecord:
        now = datetime.now(timezone.utc)
        model = await self._session.get(GrowthModel, record.id)
        if model is None:
            model = GrowthModel(id=record.id, created_at=record.created_at)
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

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(GrowthModel, id)
        if model and model.deleted_at is None:
            now = datetime.now(timezone.utc)
            model.deleted_at = now
            model.updated_at = now
            await self._session.flush()
