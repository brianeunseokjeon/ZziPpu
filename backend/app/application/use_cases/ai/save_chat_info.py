from datetime import datetime, timezone
from uuid import UUID, uuid4

from app.domain.entities.saved_info import SavedInfo
from app.domain.repositories.saved_info_repository import SavedInfoRepository


class SaveChatInfoUseCase:
    def __init__(self, saved_info_repo: SavedInfoRepository) -> None:
        self._repo = saved_info_repo

    async def execute(
        self,
        baby_id: UUID,
        title: str,
        content: str,
        category: str,
        chat_message_id: UUID | None = None,
    ) -> SavedInfo:
        info = SavedInfo(
            id=uuid4(),
            baby_id=baby_id,
            chat_message_id=chat_message_id,
            title=title,
            content=content,
            category=category,
            created_at=datetime.now(timezone.utc),
        )
        return await self._repo.save(info)
