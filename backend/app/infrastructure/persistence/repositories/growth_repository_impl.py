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
            memo=model.memo,
            created_at=model.created_at,
        )

    def _to_model(self, entity: GrowthRecord) -> GrowthModel:
        return GrowthModel(
            id=entity.id,
            baby_id=entity.baby_id,
            recorded_at=entity.recorded_at,
            weight_g=entity.weight_g,
            height_cm=entity.height_cm,
            head_circumference_cm=entity.head_circumference_cm,
            memo=entity.memo,
            created_at=entity.created_at,
        )

    async def get(self, id: UUID) -> GrowthRecord | None:
        result = await self._session.get(GrowthModel, id)
        return self._to_entity(result) if result else None

    async def get_by_baby_id(self, baby_id: UUID) -> list[GrowthRecord]:
        stmt = (
            select(GrowthModel)
            .where(GrowthModel.baby_id == baby_id)
            .order_by(GrowthModel.recorded_at.desc())
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, record: GrowthRecord) -> GrowthRecord:
        model = self._to_model(record)
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(GrowthModel, id)
        if model:
            await self._session.delete(model)
            await self._session.flush()
