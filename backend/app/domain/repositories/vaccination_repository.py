from abc import ABC, abstractmethod
from datetime import date
from uuid import UUID

from app.domain.entities.vaccination import Vaccination


class VaccinationRepository(ABC):
    @abstractmethod
    async def get_by_baby_id(self, baby_id: UUID) -> list[Vaccination]:
        ...

    @abstractmethod
    async def get_upcoming(self, baby_id: UUID, within_days: int = 30) -> list[Vaccination]:
        ...

    @abstractmethod
    async def save(self, v: Vaccination) -> Vaccination:
        ...

    @abstractmethod
    async def mark_administered(
        self,
        id: UUID,
        administered_date: date,
        hospital_name: str | None,
    ) -> Vaccination:
        ...

    @abstractmethod
    async def delete(self, id: UUID) -> None:
        ...
