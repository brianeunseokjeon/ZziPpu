from dataclasses import dataclass
from datetime import date, datetime
from uuid import UUID


@dataclass
class Baby:
    id: UUID
    user_id: UUID
    name: str
    birth_date: date
    gender: str | None
    birth_weight_g: int | None
    created_at: datetime

    @property
    def age_days(self) -> int:
        return (date.today() - self.birth_date).days

    @property
    def age_months(self) -> int:
        today = date.today()
        months = (today.year - self.birth_date.year) * 12 + (today.month - self.birth_date.month)
        if today.day < self.birth_date.day:
            months -= 1
        return max(0, months)
