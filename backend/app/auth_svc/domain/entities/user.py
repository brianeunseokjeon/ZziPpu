from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class User:
    """가벼운 신원. 이메일 OTP 로 인증된 식별자, 또는 이메일 없는 공동양육자.

    - email: 이메일 OTP 로 가입한 경우 식별자. 공동양육자(코드 로그인)는 None.
    - is_caregiver: 이메일 없이 초대코드로만 생성된 공동양육자 여부.
    """

    id: UUID
    email: str | None
    name: str | None
    is_caregiver: bool
    created_at: datetime
    deleted_at: datetime | None = None   # 탈퇴(소프트삭제) 시각. None이면 정상.
