from typing import Annotated

from fastapi import APIRouter, Depends, status

from app.application.use_cases.terms.agree_terms import AgreementInput, AgreeTermsUseCase
from app.application.use_cases.terms.get_active_terms import GetActiveTermsUseCase
from app.presentation.dependencies import (
    CurrentUserDep,
    get_active_terms_use_case,
    get_agree_terms_use_case,
)
from app.presentation.schemas.terms_schema import (
    AgreeTermsRequest,
    TermResponse,
)

router = APIRouter(prefix="/auth/terms", tags=["terms"])


@router.get("", response_model=list[TermResponse])
async def get_terms(
    use_case: Annotated[GetActiveTermsUseCase, Depends(get_active_terms_use_case)],
) -> list[TermResponse]:
    terms = await use_case.execute()
    return [
        TermResponse(
            type=t.type,
            version=t.version,
            title=t.title,
            content=t.content,
            required=t.required,
        )
        for t in terms
    ]


@router.post("/agree", status_code=status.HTTP_204_NO_CONTENT)
async def agree_terms(
    body: AgreeTermsRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[AgreeTermsUseCase, Depends(get_agree_terms_use_case)],
) -> None:
    await use_case.execute(
        user_id,
        [AgreementInput(type=a.type, version=a.version) for a in body.agreements],
    )
