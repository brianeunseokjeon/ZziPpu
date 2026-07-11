from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status

from app.application.dto.play_dto import CreatePlayDTO
from app.application.use_cases.play import (
    CreatePlayRecordUseCase,
    DeletePlayUseCase,
    GetPlayRecordsUseCase,
)
from app.presentation.dependencies import (
    CurrentUserDep,
    get_create_play_use_case,
    get_delete_play_use_case,
    get_get_plays_use_case,
)
from app.presentation.schemas.play_schema import PlayCreateRequest, PlayResponse

router = APIRouter(prefix="/babies/{baby_id}/plays", tags=["plays"])


@router.post("", response_model=PlayResponse, status_code=status.HTTP_201_CREATED)
async def create_play(
    baby_id: UUID,
    body: PlayCreateRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[CreatePlayRecordUseCase, Depends(get_create_play_use_case)],
) -> PlayResponse:
    dto = CreatePlayDTO(
        baby_id=baby_id,
        id=body.id,
        play_type=body.play_type,
        started_at=body.started_at,
        ended_at=body.ended_at,
        duration_minutes=body.duration_minutes,
        memo=body.memo,
    )
    result = await use_case.execute(dto)
    return PlayResponse(
        id=result.id,
        baby_id=result.baby_id,
        play_type=result.play_type,
        started_at=result.started_at,
        ended_at=result.ended_at,
        duration_minutes=result.duration_minutes,
        memo=result.memo,
        created_at=result.created_at,
    )


@router.get("", response_model=list[PlayResponse])
async def get_plays(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[GetPlayRecordsUseCase, Depends(get_get_plays_use_case)],
    target_date: date = Query(default_factory=date.today, alias="date"),
) -> list[PlayResponse]:
    results = await use_case.execute(baby_id, target_date)
    return [
        PlayResponse(
            id=r.id,
            baby_id=r.baby_id,
            play_type=r.play_type,
            started_at=r.started_at,
            ended_at=r.ended_at,
            duration_minutes=r.duration_minutes,
            memo=r.memo,
            created_at=r.created_at,
        )
        for r in results
    ]


@router.delete("/{play_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_play(
    baby_id: UUID,
    play_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[DeletePlayUseCase, Depends(get_delete_play_use_case)],
) -> None:
    await use_case.execute(play_id)
