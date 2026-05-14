from uuid import UUID

from app.application.dto.vaccination_dto import VaccinationResponseDTO
from app.domain.repositories.vaccination_repository import VaccinationRepository


class GetVaccinationsUseCase:
    def __init__(self, vaccination_repo: VaccinationRepository) -> None:
        self._repo = vaccination_repo

    async def execute(self, baby_id: UUID) -> list[VaccinationResponseDTO]:
        vaccinations = await self._repo.get_by_baby_id(baby_id)
        return [
            VaccinationResponseDTO(
                id=v.id,
                baby_id=v.baby_id,
                vaccine_name=v.vaccine_name,
                dose_number=v.dose_number,
                scheduled_date=v.scheduled_date,
                administered_date=v.administered_date,
                hospital_name=v.hospital_name,
                memo=v.memo,
                created_at=v.created_at,
            )
            for v in vaccinations
        ]

    async def get_upcoming(self, baby_id: UUID, within_days: int = 30) -> list[VaccinationResponseDTO]:
        vaccinations = await self._repo.get_upcoming(baby_id, within_days)
        return [
            VaccinationResponseDTO(
                id=v.id,
                baby_id=v.baby_id,
                vaccine_name=v.vaccine_name,
                dose_number=v.dose_number,
                scheduled_date=v.scheduled_date,
                administered_date=v.administered_date,
                hospital_name=v.hospital_name,
                memo=v.memo,
                created_at=v.created_at,
            )
            for v in vaccinations
        ]
