from abc import ABC, abstractmethod


class SmsService(ABC):
    """SMS 발송 인터페이스. 구현체: ConsoleSmsService(dev), NcpSensSmsService(prod)."""

    @abstractmethod
    async def send(self, phone: str, message: str) -> None:
        """phone(E.164)으로 message 발송. 실패 시 예외 발생."""
        ...
