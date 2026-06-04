from dataclasses import dataclass

from app.domain.entities.diaper import DiaperRecord
from app.domain.entities.feeding import Feeding
from app.domain.entities.play_record import PlayRecord
from app.domain.entities.sleep_record import SleepRecord
from app.domain.guidelines.diaper_guidelines import (
    get_diaper_guideline_by_months,
)
from app.domain.guidelines.feeding_guidelines import get_feeding_guideline
from app.domain.guidelines.play_guidelines import get_play_guideline
from app.domain.guidelines.sleep_guidelines import get_sleep_guideline
from app.domain.value_objects.feeding_type import FeedingType


@dataclass
class GuidelineResult:
    status: str
    message: str
    details: dict


class GuidelineService:
    def evaluate_feeding(
        self, feedings: list[Feeding], age_months: int, weight_kg: float | None = None
    ) -> GuidelineResult:
        guideline = get_feeding_guideline(age_months)
        count = len(feedings)
        min_count, max_count = guideline.daily_count_range
        total_ml = sum(f.amount_ml or 0 for f in feedings if f.feeding_type == FeedingType.FORMULA)

        details = {
            "feeding_count": count,
            "guideline_count_range": guideline.daily_count_range,
            "total_formula_ml": total_ml,
            "guideline_amount_range": guideline.amount_ml_range,
        }

        if count < min_count:
            return GuidelineResult(
                status="alert",
                message=f"수유 횟수가 너무 적습니다. 하루 {min_count}~{max_count}회 권장합니다.",
                details=details,
            )
        if count > max_count:
            return GuidelineResult(
                status="warning",
                message=f"수유 횟수가 많습니다. 하루 {min_count}~{max_count}회 권장합니다.",
                details=details,
            )
        return GuidelineResult(
            status="good",
            message=f"수유 횟수가 적절합니다. ({count}회/일)",
            details=details,
        )

    def evaluate_sleep(self, records: list[SleepRecord], age_months: int) -> GuidelineResult:
        guideline = get_sleep_guideline(age_months)
        total_minutes = sum(r.duration_minutes or 0 for r in records)
        total_hours = total_minutes / 60
        min_h, max_h = guideline.total_hours_range

        details = {
            "total_sleep_hours": round(total_hours, 1),
            "guideline_hours_range": guideline.total_hours_range,
            "sleep_sessions": len(records),
        }

        if total_hours < min_h:
            return GuidelineResult(
                status="alert",
                message=f"수면이 부족합니다. 하루 {min_h}~{max_h}시간 권장합니다.",
                details=details,
            )
        if total_hours > max_h:
            return GuidelineResult(
                status="warning",
                message=f"수면 시간이 깁니다. 하루 {min_h}~{max_h}시간 권장합니다.",
                details=details,
            )
        return GuidelineResult(
            status="good",
            message=f"수면 시간이 적절합니다. ({round(total_hours, 1)}시간/일)",
            details=details,
        )

    def evaluate_diaper(self, records: list[DiaperRecord], age_months: int) -> GuidelineResult:
        # 신생아 첫 며칠을 정밀하게 다루려면 evaluate_diaper_by_days 사용 권장.
        guideline = get_diaper_guideline_by_months(age_months)
        wet_count = sum(1 for r in records if r.diaper_type.value in ("pee", "both"))
        poo_count = sum(1 for r in records if r.diaper_type.value in ("poo", "both"))
        alert_colors = [
            r.stool_color.value for r in records
            if r.stool_color and r.stool_color.value in guideline.alert_colors
        ]
        min_poo, max_poo = guideline.poo_range

        details = {
            "wet_count": wet_count,
            "poo_count": poo_count,
            "min_wet_required": guideline.min_wet_per_day,
            "guideline_poo_range": guideline.poo_range,
            "alert_stool_colors": alert_colors,
        }

        if alert_colors:
            return GuidelineResult(
                status="alert",
                message=f"주의가 필요한 변 색상이 감지되었습니다: {', '.join(alert_colors)}",
                details=details,
            )
        if wet_count < guideline.min_wet_per_day:
            return GuidelineResult(
                status="alert",
                message=f"소변 횟수가 부족합니다. 하루 {guideline.min_wet_per_day}회 이상 권장합니다.",
                details=details,
            )
        return GuidelineResult(
            status="good",
            message=f"배변 상태가 양호합니다. (소변 {wet_count}회, 대변 {poo_count}회)",
            details=details,
        )

    def evaluate_play(self, records: list[PlayRecord], age_months: int) -> GuidelineResult:
        guideline = get_play_guideline(age_months)
        total_minutes = sum(r.duration_minutes or 0 for r in records)

        details = {
            "total_play_minutes": total_minutes,
            "recommended_tummy_time_minutes": guideline.tummy_time_minutes,
            "play_sessions": len(records),
            "recommended_activities": guideline.recommended_activities,
        }

        if total_minutes < guideline.tummy_time_minutes:
            return GuidelineResult(
                status="warning",
                message=f"놀이 시간이 부족합니다. 터미 타임 {guideline.tummy_time_minutes}분 권장합니다.",
                details=details,
            )
        return GuidelineResult(
            status="good",
            message=f"놀이 활동이 적절합니다. ({total_minutes}분/일)",
            details=details,
        )
