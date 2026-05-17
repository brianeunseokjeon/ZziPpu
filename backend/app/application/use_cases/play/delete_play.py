from uuid import UUID

from app.domain.repositories.play_repository import PlayRepository


class DeletePlayUseCase:
    def __init__(self, play_repo: PlayRepository) -> None:
        self._repo = play_repo

    async def execute(self, play_id: UUID) -> None:
        await self._repo.delete(play_id)
