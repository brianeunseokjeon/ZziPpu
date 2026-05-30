from datetime import date
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.diaper import DiaperRecord
from app.domain.repositories.diaper_repository import DiaperRepository
from app.domain.value_objects.diaper_type import DiaperType
from app.domain.value_objects.stool_color import StoolColor
from app.domain.value_objects.stool_state import StoolState
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
            memo=model.memo,
            created_at=model.created_at,
        )

    def _to_model(self, entity: DiaperRecord) -> DiaperModel:
        return DiaperModel(
            id=entity.id,
            baby_id=entity.baby_id,
            recorded_at=entity.recorded_at,
            diaper_type=entity.diaper_type.value,
            stool_color=entity.stool_color.value if entity.stool_color else None,
            stool_state=entity.stool_state.value if entity.stool_state else None,
            memo=entity.memo,
            created_at=entity.created_at,
        )

    async def get(self, id: UUID) -> DiaperRecord | None:
        result = await self._session.get(DiaperModel, id)
        return self._to_entity(result) if result else None

    async def get_by_baby_and_date(self, baby_id: UUID, target_date: date) -> list[DiaperRecord]:
        stmt = (
            select(DiaperModel)
            .where(
                DiaperModel.baby_id == baby_id,
                func.date(DiaperModel.recorded_at, '+9 hours') == target_date,
            )
            .order_by(DiaperModel.recorded_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, record: DiaperRecord) -> DiaperRecord:
        model = self._to_model(record)
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def update(self, record: DiaperRecord) -> DiaperRecord:
        model = await self._session.get(DiaperModel, record.id)
        if model is None:
            raise ValueError(f"DiaperRecord {record.id} not found")
        model.recorded_at = record.recorded_at
        model.diaper_type = record.diaper_type.value
        model.stool_color = record.stool_color.value if record.stool_color else None
        model.stool_state = record.stool_state.value if record.stool_state else None
        model.memo = record.memo
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(DiaperModel, id)
        if model:
            await self._session.delete(model)
            await self._session.flush()
