from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth_svc.domain.entities.user import User
from app.auth_svc.domain.repositories.user_repository import UserRepository
from app.auth_svc.infrastructure.persistence.models.user_model import UserModel


class UserRepositoryImpl(UserRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: UserModel) -> User:
        return User(
            id=model.id,
            email=model.email,
            name=model.name,
            is_caregiver=model.is_caregiver,
            created_at=model.created_at,
            deleted_at=model.deleted_at,
        )

    async def get(self, user_id: UUID) -> User | None:
        model = await self._session.get(UserModel, user_id)
        return self._to_entity(model) if model else None

    async def get_by_email(self, email: str) -> User | None:
        stmt = select(UserModel).where(UserModel.email == email)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def save(self, user: User) -> User:
        model = await self._session.get(UserModel, user.id)
        if model is None:
            model = UserModel(
                id=user.id,
                email=user.email,
                name=user.name,
                is_caregiver=user.is_caregiver,
                created_at=user.created_at,
            )
            self._session.add(model)
        else:
            model.email = user.email
            model.name = user.name
            model.is_caregiver = user.is_caregiver
        await self._session.flush()
        return self._to_entity(model)

    async def delete(self, user_id: UUID) -> None:
        model = await self._session.get(UserModel, user_id)
        if model is not None:
            await self._session.delete(model)
            await self._session.flush()

    async def soft_delete(self, user_id: UUID, when: datetime) -> None:
        model = await self._session.get(UserModel, user_id)
        if model is not None:
            model.deleted_at = when
            await self._session.flush()

    async def restore(self, user_id: UUID) -> None:
        model = await self._session.get(UserModel, user_id)
        if model is not None and model.deleted_at is not None:
            model.deleted_at = None
            await self._session.flush()

    async def list_purgeable_ids(self, before: datetime) -> list[UUID]:
        stmt = select(UserModel.id).where(
            UserModel.deleted_at.is_not(None), UserModel.deleted_at < before
        )
        result = await self._session.execute(stmt)
        return list(result.scalars().all())
