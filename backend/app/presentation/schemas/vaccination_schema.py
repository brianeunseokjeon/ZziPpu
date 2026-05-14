from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field, computed_field


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

    @computed_field  # type: ignore[prop-decorator]
    @property
    def is_overdue(self) -> bool:
        if self.administered_date is not None:
            return False
        return self.scheduled_date < date.today()

    @computed_field  # type: ignore[prop-decorator]
    @property
    def days_until(self) -> int | None:
        if self.administered_date is not None:
            return None
        delta = (self.scheduled_date - date.today()).days
        return delta

    model_config = {"from_attributes": True}


class MarkAdministeredRequest(BaseModel):
    administered_date: date
    hospital_name: str | None = Field(None, description="접종 병원명")
