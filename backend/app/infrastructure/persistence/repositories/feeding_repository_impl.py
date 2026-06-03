from datetime import date
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.feeding import Feeding
from app.domain.repositories.feeding_repository import FeedingRepository
from app.domain.value_objects.feeding_type import FeedingType
from app.infrastructure.persistence.models.feeding_model import FeedingModel


class FeedingRepositoryImpl(FeedingRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: FeedingModel) -> Feeding:
        return Feeding(
            id=model.id,
            baby_id=model.baby_id,
            feeding_type=FeedingType(model.feeding_type),
            started_at=model.started_at,
            ended_at=model.ended_at,
            amount_ml=model.amount_ml,
            duration_minutes=model.duration_minutes,
            memo=model.memo,
            created_at=model.created_at,
        )

    def _to_model(self, entity: Feeding) -> FeedingModel:
        return FeedingModel(
            id=entity.id,
            baby_id=entity.baby_id,
            feeding_type=entity.feeding_type.value,
            started_at=entity.started_at,
            ended_at=entity.ended_at,
            amount_ml=entity.amount_ml,
            duration_minutes=entity.duration_minutes,
            memo=entity.memo,
            created_at=entity.created_at,
        )

    async def get(self, id: UUID) -> Feeding | None:
        result = await self._session.get(FeedingModel, id)
        return self._to_entity(result) if result else None

    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[Feeding]:
        stmt = (
            select(FeedingModel)
            .where(
                FeedingModel.baby_id == baby_id,
                func.date(FeedingModel.started_at, '+9 hours') == target_date,
            )
            .order_by(FeedingModel.started_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def get_recent(self, baby_id: UUID, limit: int = 12) -> list[Feeding]:
        stmt = (
            select(FeedingModel)
            .where(FeedingModel.baby_id == baby_id)
            .order_by(FeedingModel.started_at.desc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, feeding: Feeding) -> Feeding:
        model = self._to_model(feeding)
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def update(self, feeding: Feeding) -> Feeding:
        model = await self._session.get(FeedingModel, feeding.id)
        if model is None:
            raise ValueError(f"Feeding {feeding.id} not found")
        model.feeding_type = feeding.feeding_type.value
        model.started_at = feeding.started_at
        model.ended_at = feeding.ended_at
        model.amount_ml = feeding.amount_ml
        model.duration_minutes = feeding.duration_minutes
        model.memo = feeding.memo
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(FeedingModel, id)
        if model:
            await self._session.delete(model)
            await self._session.flush()
