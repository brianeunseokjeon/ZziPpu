from collections.abc import AsyncIterator
from datetime import datetime, timezone
from uuid import UUID, uuid4

from app.application.interfaces.ai_service import AIService
from app.domain.entities.chat_message import ChatMessage
from app.domain.repositories.baby_repository import BabyRepository
from app.domain.repositories.chat_repository import ChatRepository


class ChatWithPediatricianUseCase:
    def __init__(
        self,
        baby_repo: BabyRepository,
        chat_repo: ChatRepository,
        ai_service: AIService,
    ) -> None:
        self._baby_repo = baby_repo
        self._chat_repo = chat_repo
        self._ai_service = ai_service

    async def execute(
        self,
        baby_id: UUID,
        conversation_id: UUID | None,
        user_message: str,
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

        stream = self._ai_service.chat_stream(baby, history, user_message)
        return conversation_id, stream
