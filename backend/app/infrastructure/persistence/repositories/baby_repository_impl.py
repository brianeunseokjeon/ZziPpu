from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.baby import Baby
from app.domain.repositories.baby_repository import BabyRepository
from app.infrastructure.persistence.models.baby_model import BabyModel


class BabyRepositoryImpl(BabyRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: BabyModel) -> Baby:
        return Baby(
            id=model.id,
            user_id=model.user_id,
            name=model.name,
            birth_date=model.birth_date,
            gender=model.gender,
            birth_weight_g=model.birth_weight_g,
            created_at=model.created_at,
            photo_url=model.photo_url,
        )

    def _to_model(self, entity: Baby) -> BabyModel:
        return BabyModel(
            id=entity.id,
            user_id=entity.user_id,
            name=entity.name,
            birth_date=entity.birth_date,
            gender=entity.gender,
            birth_weight_g=entity.birth_weight_g,
            created_at=entity.created_at,
            photo_url=entity.photo_url,
        )

    async def get(self, id: UUID) -> Baby | None:
        result = await self._session.get(BabyModel, id)
        if result is None or result.deleted_at is not None:
            return None
        return self._to_entity(result)

    async def get_by_user_id(self, user_id: UUID) -> list[Baby]:
        stmt = select(BabyModel).where(
            BabyModel.user_id == user_id,
            BabyModel.deleted_at.is_(None),
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]

    async def save(self, baby: Baby) -> Baby:
        # upsert(멱등): 같은 id 존재 시 갱신, 없으면 삽입.
        now = datetime.now(timezone.utc)
        model = await self._session.get(BabyModel, baby.id)
        if model is None:
            model = self._to_model(baby)
            model.deleted_at = None
            model.updated_at = now
            self._session.add(model)
        else:
            model.user_id = baby.user_id
            model.name = baby.name
            model.birth_date = baby.birth_date
            model.gender = baby.gender
            model.birth_weight_g = baby.birth_weight_g
            model.photo_url = baby.photo_url
            model.deleted_at = None
            model.updated_at = now
        await self._session.flush()
        return self._to_entity(model)

    async def update(self, baby: Baby) -> Baby:
        model = await self._session.get(BabyModel, baby.id)
        if model is None or model.deleted_at is not None:
            raise ValueError(f"Baby {baby.id} not found")
        model.name = baby.name
        model.birth_date = baby.birth_date
        model.gender = baby.gender
        model.birth_weight_g = baby.birth_weight_g
        model.photo_url = baby.photo_url
        model.updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, id: UUID) -> None:
        model = await self._session.get(BabyModel, id)
        if model and model.deleted_at is None:
            now = datetime.now(timezone.utc)
            model.deleted_at = now
            model.updated_at = now
            await self._session.flush()
