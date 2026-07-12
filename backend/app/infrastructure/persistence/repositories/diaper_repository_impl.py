from datetime import date, datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.diaper import DiaperRecord
from app.domain.repositories.diaper_repository import DiaperRepository
from app.domain.value_objects.diaper_amount import DiaperAmount
from app.domain.value_objects.diaper_type import DiaperType
from app.domain.value_objects.stool_color import StoolColor
from app.domain.value_objects.stool_state import StoolState
from app.infrastructure.persistence.db_date_utils import kst_date_eq
from app.infrastructure.persistence.models.diaper_model import DiaperModel


class DiaperRepositoryImpl(DiaperRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: DiaperModel) -> DiaperRecord:
        return DiaperRecord(
            id=model.id,
            baby_id=model.baby_id,
            recorded_at=model.recorded_at,
            diaper_type=DiaperType(model.diaper_type),
            stool_color=StoolColor(model.stool_color) if model.stool_color else None,
            stool_state=StoolState(model.stool_state) if model.stool_state else None,
            amount=DiaperAmount(model.amount) if model.amount else None,
            memo=model.memo,
            created_at=model.created_at,
        )

    def _apply_fields(self, model: DiaperModel, entity: DiaperRecord) -> None:
        model.baby_id = entity.baby_id
        model.recorded_at = entity.recorded_at
        model.diaper_type = entity.diaper_type.value
        model.stool_color = entity.stool_color.value if entity.stool_color else None
        model.stool_state = entity.stool_state.value if entity.stool_state else None
        model.amount = entity.amount.value if entity.amount else None
        model.memo = entity.memo

    async def get(self, id: UUID) -> DiaperRecord | None:
        result = await self._session.get(DiaperModel, id)
        if result is None or result.deleted_at is not None:
            return None
        return self._to_entity(result)

    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[DiaperRecord]:
        stmt = (
            select(DiaperModel)
            .where(
                DiaperModel.baby_id == baby_id,
                DiaperModel.deleted_at.is_(None),
                kst_date_eq(DiaperModel.recorded_at, target_date),
            )
            .order_by(DiaperModel.recorded_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, record: DiaperRecord) -> DiaperRecord:
        now = datetime.now(timezone.utc)
        model = await self._session.get(DiaperModel, record.id)
        if model is None:
            model = DiaperModel(id=record.id, created_at=record.created_at)
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

    async def update(self, record: DiaperRecord) -> DiaperRecord:
        model = await self._session.get(DiaperModel, record.id)
        if model is None or model.deleted_at is not None:
            raise ValueError(f"DiaperRecord {record.id} not found")
        self._apply_fields(model, record)
        model.updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(DiaperModel, id)
        if model and model.deleted_at is None:
            now = datetime.now(timezone.utc)
            model.deleted_at = now
            model.updated_at = now
            await self._session.flush()
