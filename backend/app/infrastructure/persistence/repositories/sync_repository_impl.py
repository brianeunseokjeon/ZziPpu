"""동기화 데이터 접근 — 배치 upsert(push) + 증분 pull(since 커서).

8도메인을 sync_specs 의 데이터-드리븐 스펙으로 처리한다. 각 레코드는
클라 생성 UUID 를 PK 로 그대로 사용(멱등), 서버가 updated_at 을 재타임스탬프한다.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.models.baby_model import BabyModel
from app.infrastructure.persistence.models.caregiver_model import BabyCaregiverModel
from app.infrastructure.persistence.sync.sync_specs import (
    PULL_SPECS,
    SyncSpec,
    ser_datetime,
)


class SyncRepositoryImpl:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    # ── 소유권 검증 ─────────────────────────────────────────────────────────
    async def user_can_access_baby(self, baby_id: UUID, user_id: UUID) -> bool:
        """user 가 해당 baby 의 소유자이거나 공동양육자로 합류했는지."""
        baby = await self._session.get(BabyModel, baby_id)
        if baby is None or baby.deleted_at is not None:
            return False
        if baby.user_id == user_id:
            return True
        stmt = select(BabyCaregiverModel.id).where(
            BabyCaregiverModel.baby_id == baby_id,
            BabyCaregiverModel.user_id == user_id,
        )
        result = await self._session.execute(stmt)
        return result.first() is not None

    # ── push: 배치 upsert ──────────────────────────────────────────────────
    async def upsert_one(
        self,
        spec: SyncSpec,
        baby_id: UUID,
        item: dict[str, Any],
        server_now: datetime,
    ) -> datetime:
        """단일 레코드 upsert. 서버 시각(updated_at) 반환. 실패 시 예외."""
        raw_id = item.get("id")
        if raw_id is None:
            raise ValueError("id required")
        rid = UUID(str(raw_id))

        model = await self._session.get(spec.model, rid)

        # tombstone 여부 (클라가 삭제 전파)
        deleted_at_raw = item.get("deleted_at")
        is_delete = deleted_at_raw is not None

        if model is None:
            # 신규 insert — required 필드 검증. baby_id 가 요청 baby 와 일치해야 함.
            values: dict[str, Any] = {}
            for f in spec.fields:
                if f.name in item:
                    values[f.name] = f.parse(item[f.name])
                elif f.required:
                    raise ValueError(f"missing required field '{f.name}'")
                else:
                    values[f.name] = None
            self._enforce_baby_scope(spec, values, baby_id)
            created_raw = item.get("created_at")
            created_at = (
                _parse_dt(created_raw) if created_raw is not None else server_now
            )
            model = spec.model(id=rid, created_at=created_at)
            for k, v in values.items():
                setattr(model, k, v)
            model.deleted_at = server_now if is_delete else None
            model.updated_at = server_now
            self._session.add(model)
        else:
            # 기존 update — 소유 스코프 재확인.
            self._enforce_existing_scope(spec, model, baby_id)
            for f in spec.fields:
                if f.name in item:
                    setattr(model, f.name, f.parse(item[f.name]))
            model.deleted_at = server_now if is_delete else None
            model.updated_at = server_now

        await self._session.flush()
        return model.updated_at

    def _enforce_baby_scope(self, spec: SyncSpec, values: dict, baby_id: UUID) -> None:
        # baby_id 스코프 도메인은 요청 경로의 baby_id 로 강제(위조 방지).
        if "baby_id" in values:
            values["baby_id"] = baby_id

    def _enforce_existing_scope(self, spec: SyncSpec, model: Any, baby_id: UUID) -> None:
        if hasattr(model, "baby_id") and model.baby_id != baby_id:
            raise ValueError("record belongs to a different baby")

    # ── pull: since 이후 변경분(tombstone 포함) ─────────────────────────────
    async def changes_since(
        self,
        baby_id: UUID,
        since: datetime | None,
    ) -> dict[str, list[dict[str, Any]]]:
        changes: dict[str, list[dict[str, Any]]] = {}
        for kind, spec in PULL_SPECS.items():
            model = spec.model
            if kind == "babies":
                cond = [model.id == baby_id]
            else:
                cond = [model.baby_id == baby_id]
            if since is not None:
                cond.append(model.updated_at > since)
            stmt = select(model).where(*cond).order_by(model.updated_at)
            result = await self._session.execute(stmt)
            rows = result.scalars().all()
            changes[kind] = [self._serialize(spec, m) for m in rows]
        return changes

    def _serialize(self, spec: SyncSpec, model: Any) -> dict[str, Any]:
        out: dict[str, Any] = {"id": str(model.id)}
        for f in spec.fields:
            out[f.name] = f.serialize(getattr(model, f.name))
        out["created_at"] = ser_datetime(getattr(model, "created_at", None))
        out["updated_at"] = ser_datetime(model.updated_at)
        out["deleted_at"] = ser_datetime(model.deleted_at)
        return out


def _parse_dt(v: Any) -> datetime:
    from app.infrastructure.persistence.sync.sync_specs import parse_datetime

    parsed = parse_datetime(v)
    return parsed if parsed is not None else datetime.now(timezone.utc)
