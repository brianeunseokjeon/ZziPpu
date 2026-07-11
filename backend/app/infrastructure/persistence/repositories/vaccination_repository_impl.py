from datetime import date, datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.vaccination import Vaccination
from app.domain.repositories.vaccination_repository import VaccinationRepository
from app.infrastructure.persistence.models.vaccination_model import VaccinationModel


class VaccinationRepositoryImpl(VaccinationRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: VaccinationModel) -> Vaccination:
        return Vaccination(
            id=model.id,
            baby_id=model.baby_id,
            vaccine_name=model.vaccine_name,
            dose_number=model.dose_number,
            scheduled_date=model.scheduled_date,
            administered_date=model.administered_date,
            hospital_name=model.hospital_name,
            memo=model.memo,
            created_at=model.created_at,
        )

    def _apply_fields(self, model: VaccinationModel, entity: Vaccination) -> None:
        model.baby_id = entity.baby_id
        model.vaccine_name = entity.vaccine_name
        model.dose_number = entity.dose_number
        model.scheduled_date = entity.scheduled_date
        model.administered_date = entity.administered_date
        model.hospital_name = entity.hospital_name
        model.memo = entity.memo

    async def get_by_baby_id(self, baby_id: UUID) -> list[Vaccination]:
        stmt = (
            select(VaccinationModel)
            .where(
                VaccinationModel.baby_id == baby_id,
                VaccinationModel.deleted_at.is_(None),
            )
            .order_by(VaccinationModel.scheduled_date)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def get_upcoming(self, baby_id: UUID, within_days: int = 30) -> list[Vaccination]:
        today = date.today()
        until = today + timedelta(days=within_days)
        stmt = (
            select(VaccinationModel)
            .where(
                VaccinationModel.baby_id == baby_id,
                VaccinationModel.deleted_at.is_(None),
                VaccinationModel.administered_date.is_(None),
                VaccinationModel.scheduled_date >= today,
                VaccinationModel.scheduled_date <= until,
            )
            .order_by(VaccinationModel.scheduled_date)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, v: Vaccination) -> Vaccination:
        now = datetime.now(timezone.utc)
        model = await self._session.get(VaccinationModel, v.id)
        if model is None:
            model = VaccinationModel(id=v.id, created_at=v.created_at)
            self._apply_fields(model, v)
            model.deleted_at = None
            model.updated_at = now
            self._session.add(model)
        else:
            self._apply_fields(model, v)
            model.deleted_at = None
            model.updated_at = now
        await self._session.flush()
        return self._to_entity(model)

    async def mark_administered(
        self,
        id: UUID,
        administered_date: date,
        hospital_name: str | None,
    ) -> Vaccination:
        model = await self._session.get(VaccinationModel, id)
        if model is None or model.deleted_at is not None:
            raise ValueError(f"Vaccination {id} not found")
        model.administered_date = administered_date
        model.hospital_name = hospital_name
        model.updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(VaccinationModel, id)
        if model and model.deleted_at is None:
            now = datetime.now(timezone.utc)
            model.deleted_at = now
            model.updated_at = now
            await self._session.flush()

    async def delete_pending_by_baby(self, baby_id: UUID) -> None:
        # 미접종 항목 재시드용: soft-delete 로 전환(동기화 tombstone 전파).
        stmt = (
            select(VaccinationModel)
            .where(
                VaccinationModel.baby_id == baby_id,
                VaccinationModel.deleted_at.is_(None),
                VaccinationModel.administered_date.is_(None),
            )
        )
        result = await self._session.execute(stmt)
        now = datetime.now(timezone.utc)
        for model in result.scalars().all():
            model.deleted_at = now
            model.updated_at = now
        await self._session.flush()
