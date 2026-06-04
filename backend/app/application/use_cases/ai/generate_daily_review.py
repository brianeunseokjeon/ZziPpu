from datetime import date, datetime, timezone
from uuid import UUID, uuid4

from app.application.dto.ai_dto import DailyReviewDTO
from app.application.interfaces.ai_service import AIService
from app.domain.entities.ai_review import AIReview
from app.domain.repositories.ai_review_repository import AIReviewRepository
from app.domain.repositories.baby_repository import BabyRepository
from app.domain.repositories.diaper_repository import DiaperRepository
from app.domain.repositories.feeding_repository import FeedingRepository
from app.domain.repositories.play_repository import PlayRepository
from app.domain.repositories.sleep_repository import SleepRepository


class GenerateDailyReviewUseCase:
    def __init__(
        self,
        baby_repo: BabyRepository,
        feeding_repo: FeedingRepository,
        sleep_repo: SleepRepository,
        diaper_repo: DiaperRepository,
        play_repo: PlayRepository,
        ai_review_repo: AIReviewRepository,
        ai_service: AIService,
    ) -> None:
        self._baby_repo = baby_repo
        self._feeding_repo = feeding_repo
        self._sleep_repo = sleep_repo
        self._diaper_repo = diaper_repo
        self._play_repo = play_repo
        self._ai_review_repo = ai_review_repo
        self._ai_service = ai_service

    async def execute(self, baby_id: UUID, review_date: date) -> DailyReviewDTO:
        existing = await self._ai_review_repo.get_by_baby_and_date(baby_id, review_date)
        if existing:
            return DailyReviewDTO(
                baby_id=existing.baby_id,
                review_date=existing.review_date,
                feeding_analysis=existing.feeding_analysis,
                sleep_analysis=existing.sleep_analysis,
                diaper_analysis=existing.diaper_analysis,
                play_analysis=existing.play_analysis,
                overall_assessment=existing.overall_assessment,
                alerts=existing.alerts,
                recommendations=existing.recommendations,
                positives=existing.positives,
                considerations=existing.considerations,
                concerns=existing.concerns,
                critical_warnings=existing.critical_warnings,
            )

        baby = await self._baby_repo.get(baby_id)
        if baby is None:
            raise ValueError(f"Baby {baby_id} not found")

        feedings = await self._feeding_repo.get_by_baby_and_date(baby_id, review_date)
        sleeps = await self._sleep_repo.get_by_baby_and_date(baby_id, review_date)
        diapers = await self._diaper_repo.get_by_baby_and_date(baby_id, review_date)
        plays = await self._play_repo.get_by_baby_and_date(baby_id, review_date)

        dto = await self._ai_service.generate_review(baby, feedings, sleeps, diapers, plays)

        review = AIReview(
            id=uuid4(),
            baby_id=baby_id,
            review_date=review_date,
            feeding_analysis=dto.feeding_analysis,
            sleep_analysis=dto.sleep_analysis,
            diaper_analysis=dto.diaper_analysis,
            play_analysis=dto.play_analysis,
            overall_assessment=dto.overall_assessment,
            alerts=dto.alerts,
            recommendations=dto.recommendations,
            positives=dto.positives,
            considerations=dto.considerations,
            concerns=dto.concerns,
            critical_warnings=dto.critical_warnings,
            created_at=datetime.now(timezone.utc),
        )
        await self._ai_review_repo.save(review)

        return dto
