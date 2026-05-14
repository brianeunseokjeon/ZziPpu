from datetime import date
from uuid import UUID

from app.application.dto.dashboard_dto import DailySummaryDTO
from app.domain.repositories.feeding_repository import FeedingRepository
from app.domain.repositories.sleep_repository import SleepRepository
from app.domain.repositories.diaper_repository import DiaperRepository
from app.domain.repositories.play_repository import PlayRepository
from app.domain.value_objects.feeding_type import FeedingType


class GetDailySummaryUseCase:
    def __init__(
        self,
        feeding_repo: FeedingRepository,
        sleep_repo: SleepRepository,
        diaper_repo: DiaperRepository,
        play_repo: PlayRepository,
    ) -> None:
        self._feeding_repo = feeding_repo
        self._sleep_repo = sleep_repo
        self._diaper_repo = diaper_repo
        self._play_repo = play_repo

    async def execute(self, baby_id: UUID, target_date: date) -> DailySummaryDTO:
        feedings = await self._feeding_repo.get_by_baby_and_date(baby_id, target_date)
        sleeps = await self._sleep_repo.get_by_baby_and_date(baby_id, target_date)
        diapers = await self._diaper_repo.get_by_baby_and_date(baby_id, target_date)
        plays = await self._play_repo.get_by_baby_and_date(baby_id, target_date)

        total_ml = sum(
            f.amount_ml or 0 for f in feedings if f.feeding_type == FeedingType.FORMULA
        )
        sleep_total = sum(s.duration_minutes or 0 for s in sleeps)
        play_total = sum(p.duration_minutes or 0 for p in plays)

        last_feeding = max((f.started_at for f in feedings), default=None)
        last_diaper = max((d.recorded_at for d in diapers), default=None)
        last_sleep = max((s.started_at for s in sleeps), default=None)

        return DailySummaryDTO(
            feeding_count=len(feedings),
            total_ml=total_ml,
            sleep_total_minutes=sleep_total,
            diaper_count=len(diapers),
            play_total_minutes=play_total,
            last_feeding_at=last_feeding,
            last_diaper_at=last_diaper,
            last_sleep_at=last_sleep,
        )
