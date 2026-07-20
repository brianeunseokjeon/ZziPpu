"""도메인별 동기화 스펙 — kind 문자열 ↔ SQLAlchemy 모델 + 필드 직렬화 규약.

sync push/pull 은 8도메인을 1왕복으로 처리하므로, 각 도메인의 필드 목록과
타입 변환(datetime/date ISO 파싱·직렬화)을 데이터-드리븐으로 선언한다.
새 도메인 추가는 여기 SPEC 한 줄로 확장된다(엔드포인트 로직 무변경).

- 저장 규약: 모든 datetime 컬럼은 naive UTC (UTCDateTime TypeDecorator).
- 클라 ↔ 서버 계약: datetime/date 는 ISO8601 문자열로 주고받는다.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from typing import Any, Callable
from uuid import UUID

from app.infrastructure.persistence.models.baby_model import BabyModel
from app.infrastructure.persistence.models.diaper_model import DiaperModel
from app.infrastructure.persistence.models.feeding_model import FeedingModel
from app.infrastructure.persistence.models.growth_model import GrowthModel
from app.infrastructure.persistence.models.play_model import PlayModel
from app.infrastructure.persistence.models.sleep_model import SleepModel
from app.infrastructure.persistence.models.vaccination_model import VaccinationModel

# ── 값 파서/직렬화기 ────────────────────────────────────────────────────────

def parse_datetime(v: Any) -> datetime | None:
    if v is None:
        return None
    if isinstance(v, datetime):
        dt = v
    else:
        s = str(v).replace("Z", "+00:00")
        dt = datetime.fromisoformat(s)
    # aware → UTC 정규화. naive 는 UTC 로 간주.
    if dt.tzinfo is not None:
        return dt.astimezone(timezone.utc)
    return dt.replace(tzinfo=timezone.utc)


def parse_date(v: Any) -> date | None:
    if v is None:
        return None
    if isinstance(v, date) and not isinstance(v, datetime):
        return v
    if isinstance(v, datetime):
        return v.date()
    return date.fromisoformat(str(v)[:10])


def parse_int(v: Any) -> int | None:
    return None if v is None else int(v)


def parse_float(v: Any) -> float | None:
    return None if v is None else float(v)


def parse_str(v: Any) -> str | None:
    return None if v is None else str(v)


def parse_bool(v: Any) -> bool:
    if isinstance(v, bool):
        return v
    if v is None:
        return False
    return str(v).lower() in ("1", "true", "yes")


def ser_datetime(v: datetime | None) -> str | None:
    if v is None:
        return None
    if v.tzinfo is None:
        v = v.replace(tzinfo=timezone.utc)
    return v.astimezone(timezone.utc).isoformat()


def ser_date(v: date | None) -> str | None:
    return None if v is None else v.isoformat()


def ser_passthrough(v: Any) -> Any:
    return v


@dataclass(frozen=True)
class FieldSpec:
    name: str  # 컬럼/속성명
    parse: Callable[[Any], Any]
    serialize: Callable[[Any], Any] = ser_passthrough
    required: bool = False  # insert 시 반드시 필요(신규 레코드 검증)


@dataclass(frozen=True)
class SyncSpec:
    kind: str  # push/pull 응답의 도메인 키 (예: "feedings")
    model: type
    fields: list[FieldSpec] = field(default_factory=list)


# ── 도메인 스펙 정의 ─────────────────────────────────────────────────────────

_FEEDING = SyncSpec(
    kind="feedings",
    model=FeedingModel,
    fields=[
        FieldSpec("baby_id", lambda v: UUID(str(v)), lambda v: str(v), required=True),
        FieldSpec("feeding_type", parse_str, ser_passthrough, required=True),
        FieldSpec("started_at", parse_datetime, ser_datetime, required=True),
        FieldSpec("ended_at", parse_datetime, ser_datetime),
        FieldSpec("amount_ml", parse_int, ser_passthrough),
        FieldSpec("duration_minutes", parse_int, ser_passthrough),
        FieldSpec("memo", parse_str, ser_passthrough),
        FieldSpec("did_vomit", parse_bool, ser_passthrough),
    ],
)

_SLEEP = SyncSpec(
    kind="sleeps",
    model=SleepModel,
    fields=[
        FieldSpec("baby_id", lambda v: UUID(str(v)), lambda v: str(v), required=True),
        FieldSpec("started_at", parse_datetime, ser_datetime, required=True),
        FieldSpec("ended_at", parse_datetime, ser_datetime),
        FieldSpec("memo", parse_str, ser_passthrough),
    ],
)

_DIAPER = SyncSpec(
    kind="diapers",
    model=DiaperModel,
    fields=[
        FieldSpec("baby_id", lambda v: UUID(str(v)), lambda v: str(v), required=True),
        FieldSpec("recorded_at", parse_datetime, ser_datetime, required=True),
        FieldSpec("diaper_type", parse_str, ser_passthrough, required=True),
        FieldSpec("stool_color", parse_str, ser_passthrough),
        FieldSpec("stool_state", parse_str, ser_passthrough),
        FieldSpec("amount", parse_str, ser_passthrough),
        FieldSpec("memo", parse_str, ser_passthrough),
    ],
)

_PLAY = SyncSpec(
    kind="plays",
    model=PlayModel,
    fields=[
        FieldSpec("baby_id", lambda v: UUID(str(v)), lambda v: str(v), required=True),
        FieldSpec("play_type", parse_str, ser_passthrough, required=True),
        FieldSpec("started_at", parse_datetime, ser_datetime, required=True),
        FieldSpec("ended_at", parse_datetime, ser_datetime),
        FieldSpec("duration_minutes", parse_int, ser_passthrough),
        FieldSpec("memo", parse_str, ser_passthrough),
    ],
)

_GROWTH = SyncSpec(
    kind="growths",
    model=GrowthModel,
    fields=[
        FieldSpec("baby_id", lambda v: UUID(str(v)), lambda v: str(v), required=True),
        FieldSpec("recorded_at", parse_date, ser_date, required=True),
        FieldSpec("weight_g", parse_int, ser_passthrough),
        FieldSpec("height_cm", parse_float, ser_passthrough),
        FieldSpec("head_circumference_cm", parse_float, ser_passthrough),
        FieldSpec("memo", parse_str, ser_passthrough),
    ],
)

_VACCINATION = SyncSpec(
    kind="vaccinations",
    model=VaccinationModel,
    fields=[
        FieldSpec("baby_id", lambda v: UUID(str(v)), lambda v: str(v), required=True),
        FieldSpec("vaccine_name", parse_str, ser_passthrough, required=True),
        FieldSpec("dose_number", parse_int, ser_passthrough, required=True),
        FieldSpec("scheduled_date", parse_date, ser_date, required=True),
        FieldSpec("administered_date", parse_date, ser_date),
        FieldSpec("hospital_name", parse_str, ser_passthrough),
        FieldSpec("memo", parse_str, ser_passthrough),
    ],
)

# baby 는 baby_id 대신 자기 자신이 대상. push 대상엔 넣지 않고 pull 전용(MVP §5.5).
_BABY = SyncSpec(
    kind="babies",
    model=BabyModel,
    fields=[
        FieldSpec("user_id", lambda v: UUID(str(v)), lambda v: str(v), required=True),
        FieldSpec("name", parse_str, ser_passthrough, required=True),
        FieldSpec("birth_date", parse_date, ser_date, required=True),
        FieldSpec("gender", parse_str, ser_passthrough),
        FieldSpec("birth_weight_g", parse_int, ser_passthrough),
        FieldSpec("photo_url", parse_str, ser_passthrough),
        FieldSpec("birth_height_cm", parse_float, ser_passthrough),
        FieldSpec("birth_head_circumference_cm", parse_float, ser_passthrough),
        FieldSpec("birth_chest_circumference_cm", parse_float, ser_passthrough),
        FieldSpec("blood_type", parse_str, ser_passthrough),
        FieldSpec("rh_factor", parse_str, ser_passthrough),
        FieldSpec("birth_time", parse_str, ser_passthrough),
    ],
)


# push 로 배치 업서트 가능한 도메인(baby 제외 — baby 는 별도 라우터로만 생성/수정).
PUSH_SPECS: dict[str, SyncSpec] = {
    s.kind: s
    for s in (_FEEDING, _SLEEP, _DIAPER, _PLAY, _GROWTH, _VACCINATION)
}

# pull 로 내려주는 도메인(baby 포함).
PULL_SPECS: dict[str, SyncSpec] = {
    s.kind: s
    for s in (_FEEDING, _SLEEP, _DIAPER, _PLAY, _GROWTH, _VACCINATION, _BABY)
}
