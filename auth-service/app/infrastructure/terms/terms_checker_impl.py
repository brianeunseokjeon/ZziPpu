from uuid import UUID

from app.application.interfaces.terms_checker import TermsChecker
from app.domain.repositories.terms_repository import TermsRepository


class TermsAgreementChecker(TermsChecker):
    """활성 필수 약관 중 (type, version) 미동의가 하나라도 있으면 True."""

    def __init__(self, terms_repo: TermsRepository) -> None:
        self._repo = terms_repo

    async def is_agreement_required(self, user_id: UUID) -> bool:
        active = await self._repo.get_active_terms()
        required = [(t.type, t.version) for t in active if t.required]
        if not required:
            return False
        agreed = {(a.term_type, a.term_version) for a in await self._repo.get_agreements(user_id)}
        return any(item not in agreed for item in required)
