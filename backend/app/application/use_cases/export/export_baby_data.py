import csv
import io
import json
from datetime import date
from uuid import UUID

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.models.feeding_model import FeedingModel
from app.infrastructure.persistence.models.sleep_model import SleepModel
from app.infrastructure.persistence.models.diaper_model import DiaperModel
from app.infrastructure.persistence.models.play_model import PlayModel
from app.infrastructure.persistence.models.growth_model import GrowthModel
from app.infrastructure.persistence.models.vaccination_model import VaccinationModel
from app.infrastructure.persistence.models.ai_review_model import AIReviewModel


class ExportBabyDataUseCase:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def execute(
        self,
        baby_id: UUID,
        start_date: date | None = None,
        end_date: date | None = None,
        fmt: str = "json",
    ) -> tuple[str, bytes]:
        data = await self._collect(baby_id, start_date, end_date)
        if fmt == "csv":
            return "text/csv", self._to_csv(data)
        return "application/json", json.dumps(data, ensure_ascii=False, default=str).encode("utf-8")

    async def _collect(self, baby_id: UUID, start_date: date | None, end_date: date | None) -> dict:
        from sqlalchemy import func

        def _date_filter(col):
            filters = [col == baby_id] if False else []
            if start_date:
                filters.append(func.date(col) >= start_date)
            if end_date:
                filters.append(func.date(col) <= end_date)
            return filters

        async def _query_feedings():
            stmt = select(FeedingModel).where(FeedingModel.baby_id == baby_id)
            if start_date:
                from sqlalchemy import func as f2
                stmt = stmt.where(f2.date(FeedingModel.started_at) >= start_date)
            if end_date:
                from sqlalchemy import func as f3
                stmt = stmt.where(f3.date(FeedingModel.started_at) <= end_date)
            res = await self._session.execute(stmt.order_by(FeedingModel.started_at))
            return [
                {
                    "id": str(m.id), "feeding_type": m.feeding_type,
                    "started_at": m.started_at.isoformat() if m.started_at else None,
                    "ended_at": m.ended_at.isoformat() if m.ended_at else None,
                    "amount_ml": m.amount_ml, "duration_minutes": m.duration_minutes,
                    "memo": m.memo,
                }
                for m in res.scalars().all()
            ]

        async def _query_sleeps():
            stmt = select(SleepModel).where(SleepModel.baby_id == baby_id)
            if start_date:
                from sqlalchemy import func as f2
                stmt = stmt.where(f2.date(SleepModel.started_at) >= start_date)
            if end_date:
                from sqlalchemy import func as f3
                stmt = stmt.where(f3.date(SleepModel.started_at) <= end_date)
            res = await self._session.execute(stmt.order_by(SleepModel.started_at))
            return [
                {
                    "id": str(m.id),
                    "started_at": m.started_at.isoformat() if m.started_at else None,
                    "ended_at": m.ended_at.isoformat() if m.ended_at else None,
                    "duration_minutes": m.duration_minutes, "memo": m.memo,
                }
                for m in res.scalars().all()
            ]

        async def _query_diapers():
            stmt = select(DiaperModel).where(DiaperModel.baby_id == baby_id)
            if start_date:
                from sqlalchemy import func as f2
                stmt = stmt.where(f2.date(DiaperModel.recorded_at) >= start_date)
            if end_date:
                from sqlalchemy import func as f3
                stmt = stmt.where(f3.date(DiaperModel.recorded_at) <= end_date)
            res = await self._session.execute(stmt.order_by(DiaperModel.recorded_at))
            return [
                {
                    "id": str(m.id), "diaper_type": m.diaper_type,
                    "recorded_at": m.recorded_at.isoformat() if m.recorded_at else None,
                    "stool_color": m.stool_color, "stool_state": m.stool_state, "memo": m.memo,
                }
                for m in res.scalars().all()
            ]

        async def _query_plays():
            stmt = select(PlayModel).where(PlayModel.baby_id == baby_id)
            if start_date:
                from sqlalchemy import func as f2
                stmt = stmt.where(f2.date(PlayModel.started_at) >= start_date)
            if end_date:
                from sqlalchemy import func as f3
                stmt = stmt.where(f3.date(PlayModel.started_at) <= end_date)
            res = await self._session.execute(stmt.order_by(PlayModel.started_at))
            return [
                {
                    "id": str(m.id), "play_type": m.play_type,
                    "started_at": m.started_at.isoformat() if m.started_at else None,
                    "ended_at": m.ended_at.isoformat() if m.ended_at else None,
                    "duration_minutes": m.duration_minutes, "memo": m.memo,
                }
                for m in res.scalars().all()
            ]

        async def _query_growth():
            stmt = select(GrowthModel).where(GrowthModel.baby_id == baby_id).order_by(GrowthModel.recorded_at)
            res = await self._session.execute(stmt)
            return [
                {
                    "id": str(m.id),
                    "recorded_at": m.recorded_at.isoformat() if m.recorded_at else None,
                    "weight_g": m.weight_g, "height_cm": m.height_cm,
                    "head_circumference_cm": m.head_circumference_cm, "memo": m.memo,
                }
                for m in res.scalars().all()
            ]

        async def _query_vaccinations():
            stmt = select(VaccinationModel).where(VaccinationModel.baby_id == baby_id).order_by(VaccinationModel.scheduled_date)
            res = await self._session.execute(stmt)
            return [
                {
                    "id": str(m.id), "vaccine_name": m.vaccine_name,
                    "dose_number": m.dose_number,
                    "scheduled_date": m.scheduled_date.isoformat() if m.scheduled_date else None,
                    "administered_date": m.administered_date.isoformat() if m.administered_date else None,
                    "hospital_name": m.hospital_name,
                }
                for m in res.scalars().all()
            ]

        feedings, sleeps, diapers, plays, growth, vaccinations = (
            await _query_feedings(),
            await _query_sleeps(),
            await _query_diapers(),
            await _query_plays(),
            await _query_growth(),
            await _query_vaccinations(),
        )

        return {
            "baby_id": str(baby_id),
            "export_date": date.today().isoformat(),
            "date_range": {
                "start": start_date.isoformat() if start_date else None,
                "end": end_date.isoformat() if end_date else None,
            },
            "summary": {
                "feedings": len(feedings),
                "sleeps": len(sleeps),
                "diapers": len(diapers),
                "plays": len(plays),
                "growth_records": len(growth),
                "vaccinations": len(vaccinations),
            },
            "feedings": feedings,
            "sleeps": sleeps,
            "diapers": diapers,
            "plays": plays,
            "growth_records": growth,
            "vaccinations": vaccinations,
        }

    def _to_csv(self, data: dict) -> bytes:
        buf = io.StringIO()
        writer = csv.writer(buf)

        for category in ["feedings", "sleeps", "diapers", "plays", "growth_records", "vaccinations"]:
            records = data.get(category, [])
            if not records:
                continue
            writer.writerow([f"=== {category.upper()} ==="])
            writer.writerow(list(records[0].keys()))
            for r in records:
                writer.writerow(list(r.values()))
            writer.writerow([])

        return buf.getvalue().encode("utf-8-sig")
