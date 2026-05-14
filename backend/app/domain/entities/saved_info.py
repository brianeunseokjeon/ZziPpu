from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class SavedInfo:
    id: UUID
    baby_id: UUID
    chat_message_id: UUID | None
    title: str
    content: str
    category: str
    created_at: datetime
