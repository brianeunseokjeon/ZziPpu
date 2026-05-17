from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.user import User
from app.domain.repositories.user_repository import UserRepository
from app.infrastructure.persistence.models.user_model import UserModel


class UserRepositoryImpl(UserRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: UserModel) -> User:
        return User(
            id=model.id,
            email=model.email,
            name=model.name,
            created_at=model.created_at,
            phone=model.phone,
        )

    async def get(self, id: UUID) -> User | None:
        result = await self._session.get(UserModel, id)
        return self._to_entity(result) if result else None

    async def get_by_email(self, email: str) -> User | None:
        stmt = select(UserModel).where(UserModel.email == email)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def get_by_phone(self, phone: str) -> User | None:
        stmt = select(UserModel).where(UserModel.phone == phone)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def save(self, user: User) -> User:
        model = UserModel(
            id=user.id,
            email=user.email,
            phone=user.phone,
            name=user.name,
            created_at=user.created_at,
        )
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def save_with_password(self, user: User, hashed_password: str) -> User:
        model = UserModel(
            id=user.id,
            email=user.email,
            phone=user.phone,
            name=user.name,
            hashed_password=hashed_password,
            created_at=user.created_at,
        )
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def get_hashed_password(self, email: str) -> str | None:
        stmt = select(UserModel).where(UserModel.email == email)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        if model is None:
            return None
        return model.hashed_password
