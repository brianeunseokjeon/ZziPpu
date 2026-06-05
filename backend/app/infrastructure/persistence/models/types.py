from datetime import datetime, timezone

from sqlalchemy import DateTime
from sqlalchemy.types import TypeDecorator


class UTCDateTime(TypeDecorator):
    """항상 UTC datetime을 반환한다.

    - SQLite: tzinfo 없이 저장 → 읽을 때 UTC 부여.
    - Postgres: TIMESTAMP WITHOUT TIME ZONE으로 저장 → 읽을 때 UTC 부여.
      (Postgres가 tzinfo-aware datetime을 이미 반환하는 경우도 안전하게 처리.)
    """

    impl = DateTime
    cache_ok = True

    def process_bind_param(self, value: datetime | None, dialect) -> datetime | None:
        if value is None:
            return None
        # UTC로 정규화한 뒤 naive datetime으로 저장 (DB가 timezone 컬럼이 아닐 때 안전)
        if value.tzinfo is not None:
            value = value.astimezone(timezone.utc).replace(tzinfo=None)
        return value

    def process_result_value(self, value: datetime | None, dialect) -> datetime | None:
        if value is None:
            return None
        # 이미 aware이면 UTC로 변환, naive이면 UTC 부여
        if value.tzinfo is not None:
            return value.astimezone(timezone.utc)
        return value.replace(tzinfo=timezone.utc)
