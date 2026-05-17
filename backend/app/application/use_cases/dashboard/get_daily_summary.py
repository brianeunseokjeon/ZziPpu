from datetime import date
from uuid import UUID

from app.application.dto.dashboard_dto import DailySummaryDTO
from app.domain.repositories.feeding_repository import FeedingRepository
from app.domain.repositories.sleep_repository import SleepRepository
from app.domain.repositories.diaper_repository import DiaperRepository
from app.domain.repositories.play_repository import PlayRepository
from app.domain.value_objects.feeding_type import FeedingType
from app.domain.value_objects.diaper_type import DiaperType


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

        total_feeding_ml = sum(
            f.amount_ml or 0 for f in feedings if f.feeding_type == FeedingType.FORMULA
        )
        total_sleep = sum(s.duration_minutes or 0 for s in sleeps if s.duration_minutes)
        total_play = sum(p.duration_minutes or 0 for p in plays if p.duration_minutes)
        tummy_time = sum(
            p.duration_minutes or 0 for p in plays
            if p.play_type and "tummy" in p.play_type
        )
        poop_count = sum(
            1 for d in diapers if d.diaper_type in (DiaperType.POO, DiaperType.BOTH)
        )
        pee_count = sum(
            1 for d in diapers if d.diaper_type in (DiaperType.PEE, DiaperType.BOTH)
        )

        last_feeding = max((f.started_at for f in feedings), default=None)
        last_diaper = max((d.recorded_at for d in diapers), default=None)
        last_sleep = max((s.started_at for s in sleeps), default=None)

        return DailySummaryDTO(
            total_feeding_ml=total_feeding_ml,
            feeding_count=len(feedings),
            total_sleep_minutes=total_sleep,
            sleep_count=len(sleeps),
            diaper_count=len(diapers),
            poop_count=poop_count,
            pee_count=pee_count,
            total_play_minutes=total_play,
            tummy_time_minutes=tummy_time,
            last_feeding_at=last_feeding,
            last_diaper_at=last_diaper,
            last_sleep_at=last_sleep,
        )
