from app.application.interfaces.email_sender import EmailSender


class ConsoleEmailSender(EmailSender):
    """개발용. 실제로 발송하지 않고 콘솔에 출력한다."""

    async def send(self, to: str, subject: str, html: str) -> None:
        print(f"\n📧 [DEV EMAIL] to={to} subject={subject!r}\n{html}\n")
