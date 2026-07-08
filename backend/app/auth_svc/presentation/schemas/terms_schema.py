from pydantic import BaseModel

from app.auth_svc.domain.entities.term import TermType


class TermResponse(BaseModel):
    type: TermType
    version: str
    title: str
    content: str
    required: bool


class AgreementItem(BaseModel):
    type: TermType
    version: str


class AgreeTermsRequest(BaseModel):
    agreements: list[AgreementItem]
