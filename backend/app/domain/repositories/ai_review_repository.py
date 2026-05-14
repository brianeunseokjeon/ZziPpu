from abc import ABC, abstractmethod
from datetime import date
from uuid import UUID

from app.domain.entities.ai_review import AIReview


class AIReviewRepository(ABC):
    @abstractmethod
    async def get_by_baby_and_date(self, baby_id: UUID, review_date: date) -> AIReview | None:
        ...

    @abstractmethod
    async def save(self, review: AIReview) -> AIReview:
        ...

    @abstractmethod
    async def get_recent(self, baby_id: UUID, limit: int) -> list[AIReview]:
        ...
