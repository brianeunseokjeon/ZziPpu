from dataclasses import dataclass
from datetime import date, datetime
from enum import StrEnum
from uuid import UUID


class TermType(StrEnum):
    SERVICE = "service"  # 이용약관 (필수)
    PRIVACY = "privacy"  # 개인정보 처리방침 (필수)


@dataclass
class Term:
    id: UUID
    type: TermType
    version: str
    title: str
    content: str
    is_active: bool
    required: bool
    effective_date: date


@dataclass
class TermsAgreement:
    id: UUID
    user_id: UUID
    term_type: TermType
    term_version: str
    agreed_at: datetime
