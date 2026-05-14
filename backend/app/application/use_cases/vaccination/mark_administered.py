from datetime import date
from uuid import UUID

from app.application.dto.vaccination_dto import VaccinationResponseDTO
from app.domain.repositories.vaccination_repository import VaccinationRepository


class MarkAdministeredUseCase:
    def __init__(self, vaccination_repo: VaccinationRepository) -> None:
        self._repo = vaccination_repo

    async def execute(
        self,
        id: UUID,
        administered_date: date,
        hospital_name: str | None,
    ) -> VaccinationResponseDTO:
        updated = await self._repo.mark_administered(id, administered_date, hospital_name)
        return VaccinationResponseDTO(
            id=updated.id,
            baby_id=updated.baby_id,
            vaccine_name=updated.vaccine_name,
            dose_number=updated.dose_number,
            scheduled_date=updated.scheduled_date,
            administered_date=updated.administered_date,
            hospital_name=updated.hospital_name,
            memo=updated.memo,
            created_at=updated.created_at,
        )
