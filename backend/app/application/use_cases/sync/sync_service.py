"""통합 동기화 유스케이스 — push(배치 upsert) + pull(증분).

8도메인을 1왕복으로 처리해 콜드스타트/슬립 서버 왕복을 최소화한다.
멱등: 클라 UUID = 서버 PK. 부분 실패는 accepted/rejected 로 분리해 재시도 안전.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from app.infrastructure.persistence.repositories.sync_repository_impl import (
    SyncRepositoryImpl,
)
from app.infrastructure.persistence.sync.sync_specs import (
    PUSH_SPECS,
    ser_datetime,
)


class SyncAccessDenied(Exception):
    """요청 user 가 해당 baby 에 접근할 수 없음(소유/공유 아님)."""


class SyncService:
    def __init__(self, sync_repo: SyncRepositoryImpl) -> None:
        self._repo = sync_repo

    async def _assert_access(self, baby_id: UUID, user_id: UUID) -> None:
        if not await self._repo.user_can_access_baby(baby_id, user_id):
            raise SyncAccessDenied(str(baby_id))

    async def push(
        self,
        baby_id: UUID,
        user_id: UUID,
        changes: dict[str, list[dict[str, Any]]],
    ) -> dict[str, Any]:
        await self._assert_access(baby_id, user_id)
        server_now = datetime.now(timezone.utc)

        accepted: list[dict[str, Any]] = []
        rejected: list[dict[str, Any]] = []

        for kind, items in changes.items():
            spec = PUSH_SPECS.get(kind)
            if spec is None:
                for it in items or []:
                    rejected.append(
                        {"kind": kind, "id": it.get("id"), "reason": "unknown kind"}
                    )
                continue
            for item in items or []:
                try:
                    updated_at = await self._repo.upsert_one(
                        spec, baby_id, item, server_now
                    )
                    accepted.append(
                        {
                            "kind": kind,
                            "id": str(item.get("id")),
                            "updated_at": ser_datetime(updated_at),
                        }
                    )
                except Exception as e:  # noqa: BLE001 — 부분 실패 격리(레코드 단위)
                    rejected.append(
                        {"kind": kind, "id": item.get("id"), "reason": str(e)}
                    )

        return {
            "server_time": ser_datetime(server_now),
            "accepted": accepted,
            "rejected": rejected,
        }

    async def pull(
        self,
        baby_id: UUID,
        user_id: UUID,
        since: datetime | None,
    ) -> dict[str, Any]:
        await self._assert_access(baby_id, user_id)
        # server_time 은 조회 직전 시각 → 다음 pull 커서로 사용(경계 안전하게 조회 전 캡처).
        server_now = datetime.now(timezone.utc)
        changes = await self._repo.changes_since(baby_id, since)
        return {
            "server_time": ser_datetime(server_now),
            "changes": changes,
        }
