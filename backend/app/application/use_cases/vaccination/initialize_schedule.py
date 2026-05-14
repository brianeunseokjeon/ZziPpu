from datetime import date, datetime, timedelta, timezone
from uuid import UUID, uuid4

from app.application.dto.vaccination_dto import VaccinationResponseDTO
from app.domain.entities.vaccination import Vaccination
from app.domain.guidelines.vaccination_schedule import VACCINATION_SCHEDULE
from app.domain.repositories.vaccination_repository import VaccinationRepository


class InitializeVaccinationScheduleUseCase:
    def __init__(self, vaccination_repo: VaccinationRepository) -> None:
        self._repo = vaccination_repo

    async def execute(self, baby_id: UUID, birth_date: date) -> list[VaccinationResponseDTO]:
        now = datetime.now(timezone.utc)
        saved_vaccinations: list[VaccinationResponseDTO] = []

        for entry in VACCINATION_SCHEDULE:
            scheduled_date = birth_date + timedelta(days=entry["offset_days"])
            vaccination = Vaccination(
                id=uuid4(),
                baby_id=baby_id,
                vaccine_name=entry["name"],
                dose_number=entry["dose"],
                scheduled_date=scheduled_date,
                administered_date=None,
                hospital_name=None,
                memo=None,
                created_at=now,
            )
            saved = await self._repo.save(vaccination)
            saved_vaccinations.append(
                VaccinationResponseDTO(
                    id=saved.id,
                    baby_id=saved.baby_id,
                    vaccine_name=saved.vaccine_name,
                    dose_number=saved.dose_number,
                    scheduled_date=saved.scheduled_date,
                    administered_date=saved.administered_date,
                    hospital_name=saved.hospital_name,
                    memo=saved.memo,
                    created_at=saved.created_at,
                )
            )

        return saved_vaccinations
