from datetime import datetime

from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.models.types import UTCDateTime


class SyncMixin:
    """오프라인 동기화 메타 컬럼 (전 레코드 모델 공통).

    - updated_at: LWW 병합 기준 + pull 커서(since). 항상 서버 시각으로 재타임스탬프.
    - deleted_at: tombstone(soft-delete). NULL 이면 살아있는 레코드.

    하위호환: 기존 응답 스키마는 이 컬럼을 노출하지 않아도 되며(무시 가능),
    기존 조회는 deleted_at IS NULL 로 tombstone 을 투명하게 숨긴다.
    """

    updated_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False, index=True)
    deleted_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)
