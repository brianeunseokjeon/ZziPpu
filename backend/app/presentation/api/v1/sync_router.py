from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.application.use_cases.sync import SyncService
from app.application.use_cases.sync.sync_service import SyncAccessDenied
from app.infrastructure.persistence.repositories.sync_repository_impl import (
    SyncRepositoryImpl,
)
from app.presentation.dependencies import CurrentUserDep, DbDep
from app.presentation.schemas.sync_schema import (
    SyncPullResponse,
    SyncPushRequest,
    SyncPushResponse,
)

router = APIRouter(prefix="/babies/{baby_id}/sync", tags=["sync"])


def get_sync_service(db: DbDep) -> SyncService:
    return SyncService(SyncRepositoryImpl(db))


SyncServiceDep = Annotated[SyncService, Depends(get_sync_service)]


@router.post("/push", response_model=SyncPushResponse)
async def sync_push(
    baby_id: UUID,
    body: SyncPushRequest,
    user_id: CurrentUserDep,
    service: SyncServiceDep,
) -> SyncPushResponse:
    """여러 도메인 레코드를 배치 업서트(멱등). 서버 시각 updated_at 을 ack 로 반환."""
    try:
        result = await service.push(baby_id, user_id, body.changes)
    except SyncAccessDenied:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="이 아기에 대한 접근 권한이 없습니다",
        )
    return SyncPushResponse(**result)


@router.get("/pull", response_model=SyncPullResponse)
async def sync_pull(
    baby_id: UUID,
    user_id: CurrentUserDep,
    service: SyncServiceDep,
    since: str | None = Query(
        default=None,
        description="ISO8601. 이 시각 이후 updated_at 변경분(tombstone 포함). 생략 시 전량.",
    ),
) -> SyncPullResponse:
    """since 이후 도메인별 변경분(삭제 tombstone 포함)을 1왕복으로 반환."""
    since_dt: datetime | None = None
    if since:
        try:
            s = since.replace("Z", "+00:00")
            parsed = datetime.fromisoformat(s)
            since_dt = (
                parsed.astimezone(timezone.utc)
                if parsed.tzinfo is not None
                else parsed.replace(tzinfo=timezone.utc)
            )
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="since 는 ISO8601 형식이어야 합니다",
            )
    try:
        result = await service.pull(baby_id, user_id, since_dt)
    except SyncAccessDenied:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="이 아기에 대한 접근 권한이 없습니다",
        )
    return SyncPullResponse(**result)
