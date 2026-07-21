from datetime import date, datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.care_log import CareCategory, CareLog
from app.domain.repositories.care_log_repository import CareLogRepository
from app.infrastructure.persistence.db_date_utils import kst_date_eq
from app.infrastructure.persistence.models.care_log_model import CareLogModel


class CareLogRepositoryImpl(CareLogRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: CareLogModel) -> CareLog:
        return CareLog(
            id=model.id,
            baby_id=model.baby_id,
            category=CareCategory(model.category),
            name=model.name,
            dose=model.dose,
            recorded_at=model.recorded_at,
            memo=model.memo,
            created_at=model.created_at,
        )

    def _apply_fields(self, model: CareLogModel, entity: CareLog) -> None:
        model.baby_id = entity.baby_id
        model.category = entity.category.value
        model.name = entity.name
        model.dose = entity.dose
        model.recorded_at = entity.recorded_at
        model.memo = entity.memo

    async def get(self, id: UUID) -> CareLog | None:
        result = await self._session.get(CareLogModel, id)
        if result is None or result.deleted_at is not None:
            return None
        return self._to_entity(result)

    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[CareLog]:
        stmt = (
            select(CareLogModel)
            .where(
                CareLogModel.baby_id == baby_id,
                CareLogModel.deleted_at.is_(None),
                kst_date_eq(CareLogModel.recorded_at, target_date),
            )
            .order_by(CareLogModel.recorded_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, record: CareLog) -> CareLog:
        now = datetime.now(timezone.utc)
        model = await self._session.get(CareLogModel, record.id)
        if model is None:
            model = CareLogModel(id=record.id, created_at=record.created_at)
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

    async def update(self, record: CareLog) -> CareLog:
        model = await self._session.get(CareLogModel, record.id)
        if model is None or model.deleted_at is not None:
            raise ValueError(f"CareLog {record.id} not found")
        self._apply_fields(model, record)
        model.updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(CareLogModel, id)
        if model and model.deleted_at is None:
            now = datetime.now(timezone.utc)
            model.deleted_at = now
            model.updated_at = now
            await self._session.flush()
