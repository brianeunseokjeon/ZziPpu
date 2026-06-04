from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends

from app.application.use_cases.vaccination import (
    GetVaccinationsUseCase,
    MarkAdministeredUseCase,
)
from app.presentation.dependencies import (
    CurrentUserDep,
    get_mark_administered_use_case,
    get_vaccinations_use_case,
)
from app.presentation.schemas.vaccination_schema import (
    MarkAdministeredRequest,
    VaccinationResponse,
)

router = APIRouter(prefix="/babies/{baby_id}/vaccinations", tags=["vaccinations"])


@router.get("", response_model=list[VaccinationResponse])
async def get_vaccinations(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetVaccinationsUseCase, Depends(get_vaccinations_use_case)],
) -> list[VaccinationResponse]:
    results = await use_case.execute(baby_id)
    return [
        VaccinationResponse(
            id=r.id,
            baby_id=r.baby_id,
            vaccine_name=r.vaccine_name,
            dose_number=r.dose_number,
            scheduled_date=r.scheduled_date,
            administered_date=r.administered_date,
            hospital_name=r.hospital_name,
            memo=r.memo,
            created_at=r.created_at,
        )
        for r in results
    ]


@router.get("/upcoming", response_model=list[VaccinationResponse])
async def get_upcoming_vaccinations(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetVaccinationsUseCase, Depends(get_vaccinations_use_case)],
) -> list[VaccinationResponse]:
    results = await use_case.get_upcoming(baby_id, within_days=30)
    return [
        VaccinationResponse(
            id=r.id,
            baby_id=r.baby_id,
            vaccine_name=r.vaccine_name,
            dose_number=r.dose_number,
            scheduled_date=r.scheduled_date,
            administered_date=r.administered_date,
            hospital_name=r.hospital_name,
            memo=r.memo,
            created_at=r.created_at,
        )
        for r in results
    ]


@router.post("/{vaccination_id}/administer", response_model=VaccinationResponse)
async def mark_vaccination_administered(
    baby_id: UUID,
    vaccination_id: UUID,
    body: MarkAdministeredRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[MarkAdministeredUseCase, Depends(get_mark_administered_use_case)],
) -> VaccinationResponse:
    result = await use_case.execute(
        id=vaccination_id,
        administered_date=body.administered_date,
        hospital_name=body.hospital_name,
    )
    return VaccinationResponse(
        id=result.id,
        baby_id=result.baby_id,
        vaccine_name=result.vaccine_name,
        dose_number=result.dose_number,
        scheduled_date=result.scheduled_date,
        administered_date=result.administered_date,
        hospital_name=result.hospital_name,
        memo=result.memo,
        created_at=result.created_at,
    )
