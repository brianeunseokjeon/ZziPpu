"""회원 탈퇴(소프트삭제).

deleted_at 만 설정한다(데이터는 유지). 유예기간(30일) 내 재로그인 시 자동 복구되고,
경과분은 기동 시 완전삭제(계정+전 기록)된다 — Apple 5.1.1(v) 인앱 탈퇴 요건 충족.
"""

from datetime import datetime, timezone
from uuid import UUID

from app.auth_svc.domain.repositories.user_repository import UserRepository


class WithdrawAccountUseCase:
    def __init__(self, user_repo: UserRepository) -> None:
        self._repo = user_repo

    async def execute(self, user_id: UUID) -> None:
        await self._repo.soft_delete(user_id, datetime.now(timezone.utc))
