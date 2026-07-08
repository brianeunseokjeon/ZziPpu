from abc import ABC, abstractmethod


class EmailSender(ABC):
    """이메일 발송 추상화. 구현(provider)은 교체 가능 — factory 가 env 로 선택한다."""

    @abstractmethod
    async def send(self, to: str, subject: str, html: str) -> None: ...
