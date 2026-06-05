from abc import ABC, abstractmethod
from collections.abc import AsyncIterator
from datetime import date

from app.application.dto.ai_dto import DailyReviewDTO
from app.domain.entities.baby import Baby
from app.domain.entities.chat_message import ChatMessage
from app.domain.entities.diaper import DiaperRecord
from app.domain.entities.feeding import Feeding
from app.domain.entities.play_record import PlayRecord
from app.domain.entities.sleep_record import SleepRecord


class AIService(ABC):
    @abstractmethod
    async def generate_review(
        self,
        baby: Baby,
        feedings: list[Feeding],
        sleeps: list[SleepRecord],
        diapers: list[DiaperRecord],
        plays: list[PlayRecord],
        review_date: date,
    ) -> DailyReviewDTO:
        ...

    @abstractmethod
    async def chat_stream(
        self,
        baby: Baby,
        conversation_history: list[ChatMessage],
        user_message: str,
        chat_date: date,
        feedings: list[Feeding],
        sleeps: list[SleepRecord],
        diapers: list[DiaperRecord],
        plays: list[PlayRecord],
    ) -> AsyncIterator[str]:
        ...
