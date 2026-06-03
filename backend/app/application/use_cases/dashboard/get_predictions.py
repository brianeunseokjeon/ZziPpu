from datetime import timedelta
from statistics import median
from uuid import UUID

from app.application.dto.prediction_dto import PredictionDTO
from app.domain.repositories.feeding_repository import FeedingRepository
from app.domain.repositories.sleep_repository import SleepRepository

# 신생아 정상 범위로 예측을 가둬, 이상치(밤사이 긴 공백 등)가 예측을 망치지 않게 한다.
FEEDING_MIN_INTERVAL = 90
FEEDING_MAX_INTERVAL = 240
AWAKE_MIN_WINDOW = 30
AWAKE_MAX_WINDOW = 180


def _clamp(value: float, lo: int, hi: int) -> int:
    return int(max(lo, min(hi, value)))


class GetPredictionsUseCase:
    def __init__(
        self,
        feeding_repo: FeedingRepository,
        sleep_repo: SleepRepository,
    ) -> None:
        self._feeding_repo = feeding_repo
        self._sleep_repo = sleep_repo

    async def execute(self, baby_id: UUID) -> PredictionDTO:
        feedings = await self._feeding_repo.get_recent(baby_id, limit=12)
        sleeps = await self._sleep_repo.get_recent(baby_id, limit=12)

        # get_recent은 started_at 내림차순 → 오름차순으로 뒤집어 간격 계산
        feedings_asc = list(reversed(feedings))
        sleeps_asc = list(reversed(sleeps))

        last_feeding_at = feedings_asc[-1].started_at if feedings_asc else None
        feeding_interval = self._median_interval_minutes(
            [f.started_at for f in feedings_asc]
        )
        feeding_interval = (
            _clamp(feeding_interval, FEEDING_MIN_INTERVAL, FEEDING_MAX_INTERVAL)
            if feeding_interval is not None
            else None
        )
        next_feeding_at = (
            last_feeding_at + timedelta(minutes=feeding_interval)
            if last_feeding_at and feeding_interval is not None
            else None
        )

        # 수면: 종료된 수면들 사이의 '깨어있던 시간' 중앙값으로 다음 수면 예측.
        completed = [s for s in sleeps_asc if s.ended_at is not None]
        awake_gaps: list[float] = []
        for prev, curr in zip(completed, completed[1:]):
            gap = (curr.started_at - prev.ended_at).total_seconds() / 60
            if gap > 0:
                awake_gaps.append(gap)
        awake_window = (
            _clamp(median(awake_gaps), AWAKE_MIN_WINDOW, AWAKE_MAX_WINDOW)
            if awake_gaps
            else None
        )
        last_sleep_ended_at = completed[-1].ended_at if completed else None
        # 마지막 기록이 진행 중(미종료)이면 이미 자는 중이므로 다음 수면 예측 안 함.
        is_sleeping_now = bool(sleeps_asc) and sleeps_asc[-1].ended_at is None
        next_sleep_at = (
            last_sleep_ended_at + timedelta(minutes=awake_window)
            if last_sleep_ended_at and awake_window is not None and not is_sleeping_now
            else None
        )

        return PredictionDTO(
            last_feeding_at=last_feeding_at,
            next_feeding_at=next_feeding_at,
            feeding_interval_minutes=feeding_interval,
            feeding_based_on=len(feedings_asc),
            last_sleep_ended_at=last_sleep_ended_at,
            next_sleep_at=next_sleep_at,
            awake_window_minutes=awake_window,
            sleep_based_on=len(completed),
        )

    @staticmethod
    def _median_interval_minutes(times: list) -> float | None:
        if len(times) < 2:
            return None
        gaps = [
            (b - a).total_seconds() / 60
            for a, b in zip(times, times[1:])
            if (b - a).total_seconds() > 0
        ]
        return median(gaps) if gaps else None
