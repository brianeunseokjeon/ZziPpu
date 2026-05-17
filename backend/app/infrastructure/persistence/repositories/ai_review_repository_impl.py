from datetime import date
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.ai_review import AIReview
from app.domain.repositories.ai_review_repository import AIReviewRepository
from app.infrastructure.persistence.models.ai_review_model import AIReviewModel


class AIReviewRepositoryImpl(AIReviewRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def _to_entity(self, model: AIReviewModel) -> AIReview:
        return AIReview(
            id=model.id,
            baby_id=model.baby_id,
            review_date=model.review_date,
            feeding_analysis=model.feeding_analysis,
            sleep_analysis=model.sleep_analysis,
            diaper_analysis=model.diaper_analysis,
            play_analysis=model.play_analysis,
            overall_assessment=model.overall_assessment,
            alerts=model.alerts,
            recommendations=model.recommendations,
            created_at=model.created_at,
            positives=model.positives or [],
            considerations=model.considerations or [],
            concerns=model.concerns or [],
            critical_warnings=model.critical_warnings or [],
        )

    async def get_by_baby_and_date(self, baby_id: UUID, review_date: date) -> AIReview | None:
        stmt = select(AIReviewModel).where(
            AIReviewModel.baby_id == baby_id,
            AIReviewModel.review_date == review_date,
        )
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def save(self, review: AIReview) -> AIReview:
        model = AIReviewModel(
            id=review.id,
            baby_id=review.baby_id,
            review_date=review.review_date,
            feeding_analysis=review.feeding_analysis,
            sleep_analysis=review.sleep_analysis,
            diaper_analysis=review.diaper_analysis,
            play_analysis=review.play_analysis,
            overall_assessment=review.overall_assessment,
            alerts=review.alerts,
            recommendations=review.recommendations,
            positives=review.positives,
            considerations=review.considerations,
            concerns=review.concerns,
            critical_warnings=review.critical_warnings,
            created_at=review.created_at,
        )
        self._session.add(model)
        await self._session.flush()
        return self._to_entity(model)

    async def get_recent(self, baby_id: UUID, limit: int) -> list[AIReview]:
        stmt = (
            select(AIReviewModel)
            .where(AIReviewModel.baby_id == baby_id)
            .order_by(AIReviewModel.review_date.desc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return [self._to_entity(m) for m in result.scalars().all()]
