from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class ChatMessage:
    id: UUID
    baby_id: UUID
    conversation_id: UUID
    role: str
    content: str
    created_at: datetime
