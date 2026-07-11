from typing import Any

from pydantic import BaseModel, Field


class SyncPushRequest(BaseModel):
    """도메인별 레코드 배치. 각 항목: {id, ...필드, created_at?, deleted_at?}.

    kind 키 예: feedings / sleeps / diapers / plays / growths / vaccinations.
    각 레코드는 클라 생성 UUID 를 id 로 포함(멱등 upsert). deleted_at 이 있으면 tombstone.
    """

    changes: dict[str, list[dict[str, Any]]] = Field(default_factory=dict)


class SyncAck(BaseModel):
    kind: str
    id: str | None = None
    updated_at: str | None = None


class SyncReject(BaseModel):
    kind: str
    id: Any | None = None
    reason: str


class SyncPushResponse(BaseModel):
    server_time: str
    accepted: list[SyncAck]
    rejected: list[SyncReject]


class SyncPullResponse(BaseModel):
    """since 이후 updated_at 변경분(tombstone 포함)을 도메인별로 묶어 반환."""

    server_time: str
    changes: dict[str, list[dict[str, Any]]]
