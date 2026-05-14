from abc import ABC, abstractmethod
from uuid import UUID

from app.domain.entities.chat_message import ChatMessage


class ChatRepository(ABC):
    @abstractmethod
    async def save_message(self, message: ChatMessage) -> ChatMessage:
        ...

    @abstractmethod
    async def get_conversation_messages(self, conversation_id: UUID) -> list[ChatMessage]:
        ...

    @abstractmethod
    async def get_conversations(self, baby_id: UUID) -> list[UUID]:
        ...

    @abstractmethod
    async def create_conversation(self, baby_id: UUID) -> UUID:
        ...
