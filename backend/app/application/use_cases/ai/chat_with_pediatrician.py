from collections.abc import AsyncIterator
from datetime import date, datetime, timezone
from uuid import UUID, uuid4

from app.application.interfaces.ai_service import AIService
from app.domain.entities.chat_message import ChatMessage
from app.domain.repositories.baby_repository import BabyRepository
from app.domain.repositories.care_log_repository import CareLogRepository
from app.domain.repositories.chat_repository import ChatRepository
from app.domain.repositories.diaper_repository import DiaperRepository
from app.domain.repositories.feeding_repository import FeedingRepository
from app.domain.repositories.play_repository import PlayRepository
from app.domain.repositories.sleep_repository import SleepRepository


class ChatWithPediatricianUseCase:
    def __init__(
        self,
        baby_repo: BabyRepository,
        chat_repo: ChatRepository,
        ai_service: AIService,
        feeding_repo: FeedingRepository,
        sleep_repo: SleepRepository,
        diaper_repo: DiaperRepository,
        play_repo: PlayRepository,
        care_log_repo: CareLogRepository | None = None,
    ) -> None:
        self._baby_repo = baby_repo
        self._chat_repo = chat_repo
        self._ai_service = ai_service
        self._feeding_repo = feeding_repo
        self._sleep_repo = sleep_repo
        self._diaper_repo = diaper_repo
        self._play_repo = play_repo
        self._care_log_repo = care_log_repo

    async def execute(
        self,
        baby_id: UUID,
        conversation_id: UUID | None,
        user_message: str,
        chat_date: date,
    ) -> tuple[UUID, AsyncIterator[str]]:
        baby = await self._baby_repo.get(baby_id)
        if baby is None:
            raise ValueError(f"Baby {baby_id} not found")

        if conversation_id is None:
            conversation_id = await self._chat_repo.create_conversation(baby_id)

        history = await self._chat_repo.get_conversation_messages(conversation_id)

        user_msg = ChatMessage(
            id=uuid4(),
            baby_id=baby_id,
            conversation_id=conversation_id,
            role="user",
            content=user_message,
            created_at=datetime.now(timezone.utc),
        )
        await self._chat_repo.save_message(user_msg)

        # 상담 기준 날짜의 기록을 컨텍스트로 전달
        feedings = await self._feeding_repo.get_by_baby_and_date(baby_id, chat_date)
        sleeps = await self._sleep_repo.get_by_baby_and_date(baby_id, chat_date)
        diapers = await self._diaper_repo.get_by_baby_and_date(baby_id, chat_date)
        plays = await self._play_repo.get_by_baby_and_date(baby_id, chat_date)
        care_logs = (
            await self._care_log_repo.get_by_baby_and_date(baby_id, chat_date)
            if self._care_log_repo is not None
            else None
        )

        stream = self._ai_service.chat_stream(
            baby, history, user_message, chat_date, feedings, sleeps, diapers, plays, care_logs
        )
        return conversation_id, stream
