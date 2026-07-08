from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth_svc.domain.entities.term import Term, TermsAgreement, TermType
from app.auth_svc.domain.repositories.terms_repository import TermsRepository
from app.auth_svc.infrastructure.persistence.models.term_model import TermModel, TermsAgreementModel


class TermsRepositoryImpl(TermsRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_term(self, m: TermModel) -> Term:
        return Term(
            id=m.id,
            type=TermType(m.type),
            version=m.version,
            title=m.title,
            content=m.content,
            is_active=m.is_active,
            required=m.required,
            effective_date=m.effective_date,
        )

    async def get_active_terms(self) -> list[Term]:
        stmt = select(TermModel).where(TermModel.is_active.is_(True)).order_by(TermModel.type)
        result = await self._session.execute(stmt)
        return [self._to_term(m) for m in result.scalars().all()]

    async def upsert_term(self, term: Term) -> None:
        stmt = select(TermModel).where(
            TermModel.type == term.type.value, TermModel.version == term.version
        )
        existing = (await self._session.execute(stmt)).scalar_one_or_none()
        if existing is None:
            self._session.add(
                TermModel(
                    id=term.id,
                    type=term.type.value,
                    version=term.version,
                    title=term.title,
                    content=term.content,
                    is_active=term.is_active,
                    required=term.required,
                    effective_date=term.effective_date,
                )
            )
        else:
            existing.title = term.title
            existing.content = term.content
            existing.is_active = term.is_active
            existing.required = term.required
            existing.effective_date = term.effective_date
        await self._session.flush()

    async def deactivate_others(self, term_type: TermType, keep_version: str) -> None:
        stmt = (
            update(TermModel)
            .where(TermModel.type == term_type.value, TermModel.version != keep_version)
            .values(is_active=False)
        )
        await self._session.execute(stmt)
        await self._session.flush()

    async def get_agreements(self, user_id: UUID) -> list[TermsAgreement]:
        stmt = select(TermsAgreementModel).where(TermsAgreementModel.user_id == user_id)
        result = await self._session.execute(stmt)
        return [
            TermsAgreement(
                id=m.id,
                user_id=m.user_id,
                term_type=TermType(m.term_type),
                term_version=m.term_version,
                agreed_at=m.agreed_at,
            )
            for m in result.scalars().all()
        ]

    async def add_agreement(self, agreement: TermsAgreement) -> None:
        self._session.add(
            TermsAgreementModel(
                id=agreement.id,
                user_id=agreement.user_id,
                term_type=agreement.term_type.value,
                term_version=agreement.term_version,
                agreed_at=agreement.agreed_at,
            )
        )
        await self._session.flush()
