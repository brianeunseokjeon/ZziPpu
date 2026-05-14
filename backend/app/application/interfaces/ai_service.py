from abc import ABC, abstractmethod
from collections.abc import AsyncIterator
from uuid import UUID

from app.domain.entities.baby import Baby
from app.domain.entities.feeding import Feeding
from app.domain.entities.sleep_record import SleepRecord
from app.domain.entities.diaper import DiaperRecord
from app.domain.entities.play_record import PlayRecord
from app.domain.entities.chat_message import ChatMessage
from app.application.dto.ai_dto import DailyReviewDTO


class AIService(ABC):
    @abstractmethod
    async def generate_review(
        self,
        baby: Baby,
        feedings: list[Feeding],
        sleeps: list[SleepRecord],
        diapers: list[DiaperRecord],
        plays: list[PlayRecord],
    ) -> DailyReviewDTO:
        ...

    @abstractmethod
    async def chat_stream(
        self,
        baby: Baby,
        conversation_history: list[ChatMessage],
        user_message: str,
    ) -> AsyncIterator[str]:
        ...
