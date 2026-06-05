"""DB 방언(SQLite / PostgreSQL) 호환 날짜 필터 유틸.

SQLite: func.date(col, '+9 hours') — 2인자 허용
Postgres: func.timezone('Asia/Seoul', col)::date — 1인자만 허용

모든 리포지토리에서 이 유틸을 통해 날짜 필터를 생성한다(저결합).
"""

from datetime import date

from sqlalchemy import Date, cast, func
from sqlalchemy.sql.elements import ColumnElement

from app.infrastructure.persistence.database import _is_sqlite


def kst_date_eq(column: ColumnElement, target: date) -> ColumnElement:
    """KST 기준으로 column 이 target 날짜인 조건 (SQLite / Postgres 호환)."""
    if _is_sqlite:
        return func.date(column, "+9 hours") == target
    # Postgres: UTC 타임스탬프 → KST 변환 후 DATE 비교
    return cast(func.timezone("Asia/Seoul", column), Date) == target
