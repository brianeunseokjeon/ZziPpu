from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.saved_info import SavedInfo
from app.domain.repositories.saved_info_repository import SavedInfoRepository
from app.infrastructure.persistence.models.saved_info_model import SavedInfoModel


class SavedInfoRepositoryImpl(SavedInfoRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: SavedInfoModel) -> SavedInfo:
        return SavedInfo(
            id=model.id,
            baby_id=model.baby_id,
            chat_message_id=model.chat_message_id,
            title=model.title,
            content=model.content,
            category=model.category,
            created_at=model.created_at,
        )

    async def get(self, id: UUID) -> SavedInfo | None:
        result = await self._session.get(SavedInfoModel, id)
        return self._to_entity(result) if result else None

    async def get_by_baby_id(self, baby_id: UUID) -> list[SavedInfo]:
        stmt = (
            select(SavedInfoModel)
            .where(SavedInfoModel.baby_id == baby_id)
            .order_by(SavedInfoModel.created_at.desc())
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, info: SavedInfo) -> SavedInfo:
        model = SavedInfoModel(
            id=info.id,
            baby_id=info.baby_id,
            chat_message_id=info.chat_message_id,
            title=info.title,
            content=info.content,
            category=info.category,
            created_at=info.created_at,
        )
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(SavedInfoModel, id)
        if model:
            await self._session.delete(model)
            await self._session.flush()
