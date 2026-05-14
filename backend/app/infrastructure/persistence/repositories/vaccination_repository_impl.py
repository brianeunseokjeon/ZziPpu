from datetime import date, timedelta
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

    def _to_model(self, entity: Vaccination) -> VaccinationModel:
        return VaccinationModel(
            id=entity.id,
            baby_id=entity.baby_id,
            vaccine_name=entity.vaccine_name,
            dose_number=entity.dose_number,
            scheduled_date=entity.scheduled_date,
            administered_date=entity.administered_date,
            hospital_name=entity.hospital_name,
            memo=entity.memo,
            created_at=entity.created_at,
        )

    async def get_by_baby_id(self, baby_id: UUID) -> list[Vaccination]:
        stmt = (
            select(VaccinationModel)
            .where(VaccinationModel.baby_id == baby_id)
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
                VaccinationModel.administered_date.is_(None),
                VaccinationModel.scheduled_date >= today,
                VaccinationModel.scheduled_date <= until,
            )
            .order_by(VaccinationModel.scheduled_date)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, v: Vaccination) -> Vaccination:
        model = self._to_model(v)
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def mark_administered(
        self,
        id: UUID,
        administered_date: date,
        hospital_name: str | None,
    ) -> Vaccination:
        model = await self._session.get(VaccinationModel, id)
        if model is None:
            raise ValueError(f"Vaccination {id} not found")
        model.administered_date = administered_date
        model.hospital_name = hospital_name
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(VaccinationModel, id)
        if model:
            await self._session.delete(model)
            await self._session.flush()
