from abc import ABC, abstractmethod
from uuid import UUID

from app.domain.entities.term import Term, TermsAgreement, TermType


class TermsRepository(ABC):
    @abstractmethod
    async def get_active_terms(self) -> list[Term]: ...

    @abstractmethod
    async def upsert_term(self, term: Term) -> None: ...

    @abstractmethod
    async def deactivate_others(self, term_type: TermType, keep_version: str) -> None: ...

    @abstractmethod
    async def get_agreements(self, user_id: UUID) -> list[TermsAgreement]: ...

    @abstractmethod
    async def add_agreement(self, agreement: TermsAgreement) -> None: ...
