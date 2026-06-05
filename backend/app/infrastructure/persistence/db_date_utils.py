"""DB 방언(SQLite / PostgreSQL) 호환 KST 날짜 필터 유틸.

저장 규약: 모든 datetime 컬럼은 **naive UTC**(tzinfo 없이 UTC 기준)로 저장된다
(UTCDateTime TypeDecorator 참고). 따라서 "KST 기준 날짜"로 그룹핑하려면
naive UTC → KST 로 변환한 뒤 날짜를 추출해야 한다.

- SQLite: func.date(col, '+9 hours') — naive UTC 에 9시간을 더해 KST 로 변환 후 날짜.
- Postgres: timezone('Asia/Seoul', timezone('UTC', col))::date
    1) timezone('UTC', col): naive 값을 'UTC 시각'으로 해석 → timestamptz
    2) timezone('Asia/Seoul', ...): 해당 timestamptz 를 KST 벽시계로 변환 → naive
    3) ::date: KST 기준 날짜 추출
  ⚠️ timezone('Asia/Seoul', col) 한 번만 쓰면 naive 를 KST 로 *해석*해버려
     날짜가 하루 밀린다(과거 버그). 반드시 UTC 해석을 먼저 거쳐야 한다.

모든 리포지토리는 이 유틸을 통해서만 KST 날짜 필터를 만든다(분기 응집).
"""

from datetime import date

from sqlalchemy import Date, cast, func
from sqlalchemy.sql.elements import ColumnElement

from app.infrastructure.persistence.database import _is_sqlite


def kst_date_expr(column: ColumnElement) -> ColumnElement:
    """naive UTC 컬럼 → KST 기준 DATE 표현식 (SQLite / Postgres 호환)."""
    if _is_sqlite:
        return func.date(column, "+9 hours")
    return cast(func.timezone("Asia/Seoul", func.timezone("UTC", column)), Date)


def kst_date_eq(column: ColumnElement, target: date) -> ColumnElement:
    """KST 기준으로 column 의 날짜가 target 과 같은지 비교하는 조건."""
    return kst_date_expr(column) == target
