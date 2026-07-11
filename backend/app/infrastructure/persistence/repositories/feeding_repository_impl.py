from datetime import date, datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.feeding import Feeding
from app.domain.repositories.feeding_repository import FeedingRepository
from app.domain.value_objects.feeding_type import FeedingType
from app.infrastructure.persistence.db_date_utils import kst_date_eq
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

    def _apply_fields(self, model: FeedingModel, entity: Feeding) -> None:
        model.baby_id = entity.baby_id
        model.feeding_type = entity.feeding_type.value
        model.started_at = entity.started_at
        model.ended_at = entity.ended_at
        model.amount_ml = entity.amount_ml
        model.duration_minutes = entity.duration_minutes
        model.memo = entity.memo

    async def get(self, id: UUID) -> Feeding | None:
        result = await self._session.get(FeedingModel, id)
        if result is None or result.deleted_at is not None:
            return None
        return self._to_entity(result)

    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[Feeding]:
        stmt = (
            select(FeedingModel)
            .where(
                FeedingModel.baby_id == baby_id,
                FeedingModel.deleted_at.is_(None),
                kst_date_eq(FeedingModel.started_at, target_date),
            )
            .order_by(FeedingModel.started_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def get_recent(self, baby_id: UUID, limit: int = 12) -> list[Feeding]:
        stmt = (
            select(FeedingModel)
            .where(
                FeedingModel.baby_id == baby_id,
                FeedingModel.deleted_at.is_(None),
            )
            .order_by(FeedingModel.started_at.desc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, feeding: Feeding) -> Feeding:
        # upsert(멱등): 같은 id 존재 시 갱신, 없으면 삽입. 재시도 안전.
        now = datetime.now(timezone.utc)
        model = await self._session.get(FeedingModel, feeding.id)
        if model is None:
            model = FeedingModel(id=feeding.id, created_at=feeding.created_at)
            self._apply_fields(model, feeding)
            model.deleted_at = None
            model.updated_at = now
            self._session.add(model)
        else:
            self._apply_fields(model, feeding)
            model.deleted_at = None
            model.updated_at = now
        await self._session.flush()
        return self._to_entity(model)

    async def update(self, feeding: Feeding) -> Feeding:
        model = await self._session.get(FeedingModel, feeding.id)
        if model is None or model.deleted_at is not None:
            raise ValueError(f"Feeding {feeding.id} not found")
        self._apply_fields(model, feeding)
        model.updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(FeedingModel, id)
        if model and model.deleted_at is None:
            now = datetime.now(timezone.utc)
            model.deleted_at = now
            model.updated_at = now
            await self._session.flush()
