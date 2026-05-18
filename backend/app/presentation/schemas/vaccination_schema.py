from datetime import date, datetime, timedelta
from uuid import UUID

from pydantic import BaseModel, Field, computed_field

from app.domain.guidelines.vaccination_schedule import (
    DEFAULT_GRACE_DAYS,
    GRACE_DAYS_BY_VACCINE,
)


class VaccinationResponse(BaseModel):
    id: UUID
    baby_id: UUID
    vaccine_name: str
    dose_number: int
    scheduled_date: date
    administered_date: date | None
    hospital_name: str | None
    memo: str | None
    created_at: datetime

    def _grace_days(self) -> int:
        return GRACE_DAYS_BY_VACCINE.get(
            (self.vaccine_name, self.dose_number),
            DEFAULT_GRACE_DAYS,
        )

    @computed_field  # type: ignore[prop-decorator]
    @property
    def is_overdue(self) -> bool:
        """권장일이 지났더라도 grace 기간 안에는 '예정' 상태로 본다."""
        if self.administered_date is not None:
            return False
        deadline = self.scheduled_date + timedelta(days=self._grace_days())
        return date.today() > deadline

    @computed_field  # type: ignore[prop-decorator]
    @property
    def days_until(self) -> int | None:
        """양수: 권장일까지 며칠 남음. 0: 오늘. 음수: 권장일 지남 (grace 이내일 수도 있음)."""
        if self.administered_date is not None:
            return None
        return (self.scheduled_date - date.today()).days

    model_config = {"from_attributes": True}


class MarkAdministeredRequest(BaseModel):
    administered_date: date
    hospital_name: str | None = Field(None, description="접종 병원명")
