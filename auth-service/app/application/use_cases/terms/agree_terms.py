from dataclasses import dataclass
from datetime import datetime, timezone
from uuid import UUID, uuid4

from app.domain.entities.term import TermsAgreement, TermType
from app.domain.repositories.terms_repository import TermsRepository


@dataclass
class AgreementInput:
    type: TermType
    version: str


class AgreeTermsUseCase:
    def __init__(self, terms_repo: TermsRepository) -> None:
        self._repo = terms_repo

    async def execute(self, user_id: UUID, agreements: list[AgreementInput]) -> None:
        existing = {
            (a.term_type, a.term_version) for a in await self._repo.get_agreements(user_id)
        }
        now = datetime.now(timezone.utc)
        for a in agreements:
            if (a.type, a.version) in existing:
                continue
            await self._repo.add_agreement(
                TermsAgreement(
                    id=uuid4(),
                    user_id=user_id,
                    term_type=a.type,
                    term_version=a.version,
                    agreed_at=now,
                )
            )
