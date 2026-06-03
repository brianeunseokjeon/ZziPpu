from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.caregiver import Caregiver, CaregiverInvite
from app.domain.repositories.caregiver_repository import CaregiverRepository
from app.infrastructure.persistence.models.caregiver_model import (
    BabyCaregiverModel,
    CaregiverInviteModel,
)


class CaregiverRepositoryImpl(CaregiverRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    @staticmethod
    def _member_to_entity(m: BabyCaregiverModel) -> Caregiver:
        return Caregiver(
            id=m.id,
            baby_id=m.baby_id,
            user_id=m.user_id,
            role=m.role,
            created_at=m.created_at,
        )

    @staticmethod
    def _invite_to_entity(m: CaregiverInviteModel) -> CaregiverInvite:
        return CaregiverInvite(
            id=m.id,
            baby_id=m.baby_id,
            code=m.code,
            created_by=m.created_by,
            expires_at=m.expires_at,
            used_at=m.used_at,
            created_at=m.created_at,
        )

    async def add_member(self, baby_id: UUID, user_id: UUID, role: str = "caregiver") -> Caregiver:
        model = BabyCaregiverModel(
            id=uuid4(),
            baby_id=baby_id,
            user_id=user_id,
            role=role,
            created_at=datetime.utcnow(),
        )
        self._session.add(model)
        await self._session.flush()
        return self._member_to_entity(model)

    async def get_baby_ids_for_user(self, user_id: UUID) -> list[UUID]:
        stmt = select(BabyCaregiverModel.baby_id).where(BabyCaregiverModel.user_id == user_id)
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def is_member(self, baby_id: UUID, user_id: UUID) -> bool:
        stmt = select(BabyCaregiverModel.id).where(
            BabyCaregiverModel.baby_id == baby_id,
            BabyCaregiverModel.user_id == user_id,
        )
        result = await self._session.execute(stmt)
        return result.first() is not None

    async def list_members(self, baby_id: UUID) -> list[Caregiver]:
        stmt = (
            select(BabyCaregiverModel)
            .where(BabyCaregiverModel.baby_id == baby_id)
            .order_by(BabyCaregiverModel.created_at)
        )
        result = await self._session.execute(stmt)
        return [self._member_to_entity(m) for m in result.scalars().all()]

    async def create_invite(
        self, baby_id: UUID, created_by: UUID, code: str, expires_at: datetime
    ) -> CaregiverInvite:
        model = CaregiverInviteModel(
            id=uuid4(),
            baby_id=baby_id,
            code=code,
            created_by=created_by,
            expires_at=expires_at,
            used_at=None,
            created_at=datetime.utcnow(),
        )
        self._session.add(model)
        await self._session.flush()
        return self._invite_to_entity(model)

    async def get_invite_by_code(self, code: str) -> CaregiverInvite | None:
        stmt = select(CaregiverInviteModel).where(CaregiverInviteModel.code == code)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._invite_to_entity(model) if model else None

    async def mark_invite_used(self, invite_id: UUID, used_at: datetime) -> None:
        model = await self._session.get(CaregiverInviteModel, invite_id)
        if model:
            model.used_at = used_at
            await self._session.flush()
