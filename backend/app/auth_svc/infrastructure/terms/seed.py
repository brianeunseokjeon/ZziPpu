from datetime import date
from pathlib import Path
from uuid import uuid5, NAMESPACE_URL

from app.auth_svc.domain.entities.term import Term, TermType
from app.auth_svc.domain.repositories.terms_repository import TermsRepository

_CONTENT_DIR = Path(__file__).resolve().parents[2] / "content" / "terms"

# 활성 약관 정의. 파일/버전을 바꾸면 교체된다.
_ACTIVE_TERMS = [
    {
        "type": TermType.SERVICE,
        "version": "v1",
        "title": "이용약관",
        "file": "service_terms_v1.md",
        "required": True,
        "effective_date": date(2026, 1, 1),
    },
    {
        "type": TermType.PRIVACY,
        "version": "v1",
        "title": "개인정보 처리방침",
        "file": "privacy_policy_v1.md",
        "required": True,
        "effective_date": date(2026, 1, 1),
    },
]


async def seed_terms(repo: TermsRepository) -> None:
    """마크다운 본문 → terms 테이블 upsert. lifespan 에서 호출."""
    for spec in _ACTIVE_TERMS:
        content = (_CONTENT_DIR / spec["file"]).read_text(encoding="utf-8")
        term_type: TermType = spec["type"]
        version: str = spec["version"]
        await repo.upsert_term(
            Term(
                id=uuid5(NAMESPACE_URL, f"term:{term_type.value}:{version}"),
                type=term_type,
                version=version,
                title=spec["title"],
                content=content,
                is_active=True,
                required=spec["required"],
                effective_date=spec["effective_date"],
            )
        )
        await repo.deactivate_others(term_type, version)
