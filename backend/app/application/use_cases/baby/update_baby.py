from datetime import datetime, timedelta, timezone
from uuid import uuid4

from app.application.dto.baby_dto import BabyResponseDTO, UpdateBabyDTO
from app.domain.entities.vaccination import Vaccination
from app.domain.guidelines.vaccination_schedule import VACCINATION_SCHEDULE
from app.domain.repositories.baby_repository import BabyRepository
from app.domain.repositories.vaccination_repository import VaccinationRepository


class UpdateBabyUseCase:
    def __init__(
        self,
        baby_repo: BabyRepository,
        vaccination_repo: VaccinationRepository,
    ) -> None:
        self._repo = baby_repo
        self._vacc_repo = vaccination_repo

    async def execute(self, dto: UpdateBabyDTO) -> BabyResponseDTO:
        baby = await self._repo.get(dto.id)
        if baby is None:
            raise ValueError(f"Baby {dto.id} not found")

        birth_date_changed = (
            dto.birth_date is not None and dto.birth_date != baby.birth_date
        )

        if dto.name is not None:
            baby.name = dto.name
        if dto.birth_date is not None:
            baby.birth_date = dto.birth_date
        if dto.gender is not None:
            baby.gender = dto.gender
        if dto.birth_weight_g is not None:
            baby.birth_weight_g = dto.birth_weight_g
        if dto.photo_url is not None:
            baby.photo_url = dto.photo_url

        saved = await self._repo.update(baby)

        # 생년월일이 바뀌면 미접종 예방접종 일정을 재계산
        # (이미 접종 완료한 것은 보존)
        if birth_date_changed:
            await self._regenerate_pending_vaccinations(saved.id, saved.birth_date)

        return BabyResponseDTO(
            id=saved.id,
            user_id=saved.user_id,
            name=saved.name,
            birth_date=saved.birth_date,
            gender=saved.gender,
            birth_weight_g=saved.birth_weight_g,
            age_days=saved.age_days,
            age_months=saved.age_months,
            created_at=saved.created_at,
            photo_url=saved.photo_url,
        )

    async def _regenerate_pending_vaccinations(self, baby_id, birth_date) -> None:
        # 이미 접종한 항목 (vaccine_name, dose_number) 셋 수집
        existing = await self._vacc_repo.get_by_baby_id(baby_id)
        administered_keys = {
            (v.vaccine_name, v.dose_number)
            for v in existing
            if v.administered_date is not None
        }

        # 미접종 항목 전체 삭제
        await self._vacc_repo.delete_pending_by_baby(baby_id)

        # 새 birth_date 기준으로 미접종 항목 재생성
        now = datetime.now(timezone.utc)
        for entry in VACCINATION_SCHEDULE:
            key = (entry["name"], entry["dose"])
            if key in administered_keys:
                continue  # 이미 접종 완료, 보존
            scheduled = birth_date + timedelta(days=entry["offset_days"])
            await self._vacc_repo.save(
                Vaccination(
                    id=uuid4(),
                    baby_id=baby_id,
                    vaccine_name=entry["name"],
                    dose_number=entry["dose"],
                    scheduled_date=scheduled,
                    administered_date=None,
                    hospital_name=None,
                    memo=None,
                    created_at=now,
                )
            )
