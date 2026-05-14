from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.chat_message import ChatMessage
from app.domain.repositories.chat_repository import ChatRepository
from app.infrastructure.persistence.models.chat_conversation_model import ChatConversationModel
from app.infrastructure.persistence.models.chat_message_model import ChatMessageModel


class ChatRepositoryImpl(ChatRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: ChatMessageModel) -> ChatMessage:
        return ChatMessage(
            id=model.id,
            baby_id=model.baby_id,
            conversation_id=model.conversation_id,
            role=model.role,
            content=model.content,
            created_at=model.created_at,
        )

    async def save_message(self, message: ChatMessage) -> ChatMessage:
        model = ChatMessageModel(
            id=message.id,
            baby_id=message.baby_id,
            conversation_id=message.conversation_id,
            role=message.role,
            content=message.content,
            created_at=message.created_at,
        )
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def get_conversation_messages(self, conversation_id: UUID) -> list[ChatMessage]:
        stmt = (
            select(ChatMessageModel)
            .where(ChatMessageModel.conversation_id == conversation_id)
            .order_by(ChatMessageModel.created_at)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def get_conversations(self, baby_id: UUID) -> list[UUID]:
        stmt = (
            select(ChatConversationModel.id)
            .where(ChatConversationModel.baby_id == baby_id)
            .order_by(ChatConversationModel.created_at.desc())
        )
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def create_conversation(self, baby_id: UUID) -> UUID:
        conversation_id = uuid4()
        model = ChatConversationModel(
            id=conversation_id,
            baby_id=baby_id,
            created_at=datetime.now(timezone.utc),
        )
        self._session.add(model)
        await self._session.flush()
        return conversation_id
