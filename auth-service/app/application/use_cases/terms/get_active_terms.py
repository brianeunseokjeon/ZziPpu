from app.domain.entities.term import Term
from app.domain.repositories.terms_repository import TermsRepository


class GetActiveTermsUseCase:
    def __init__(self, terms_repo: TermsRepository) -> None:
        self._repo = terms_repo

    async def execute(self) -> list[Term]:
        return await self._repo.get_active_terms()
