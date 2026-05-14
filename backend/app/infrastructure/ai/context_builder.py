from app.domain.entities.baby import Baby
from app.domain.entities.feeding import Feeding
from app.domain.entities.sleep_record import SleepRecord
from app.domain.entities.diaper import DiaperRecord
from app.domain.entities.play_record import PlayRecord
from app.domain.value_objects.feeding_type import FeedingType


def build_daily_context(
    baby: Baby,
    feedings: list[Feeding],
    sleeps: list[SleepRecord],
    diapers: list[DiaperRecord],
    plays: list[PlayRecord],
) -> str:
    lines = [
        f"아기 정보:",
        f"  이름: {baby.name}",
        f"  생후: {baby.age_days}일 ({baby.age_months}개월)",
        "",
        "수유 기록:",
    ]

    if feedings:
        for f in feedings:
            time_str = f.started_at.strftime("%H:%M")
            type_map = {
                FeedingType.FORMULA: "분유",
                FeedingType.BREAST_LEFT: "모유(왼쪽)",
                FeedingType.BREAST_RIGHT: "모유(오른쪽)",
                FeedingType.BREAST_BOTH: "모유(양쪽)",
            }
            type_label = type_map.get(f.feeding_type, f.feeding_type.value)
            amount = f"{f.amount_ml}ml" if f.amount_ml else ""
            duration = f"{f.duration_minutes}분" if f.duration_minutes else ""
            detail = ", ".join(filter(None, [amount, duration]))
            lines.append(f"  {time_str} - {type_label} {detail}")
        total_ml = sum(f.amount_ml or 0 for f in feedings if f.feeding_type == FeedingType.FORMULA)
        lines.append(f"  합계: {len(feedings)}회, 분유 총 {total_ml}ml")
    else:
        lines.append("  기록 없음")

    lines.append("")
    lines.append("수면 기록:")
    if sleeps:
        total_minutes = 0
        for s in sleeps:
            start_str = s.started_at.strftime("%H:%M")
            end_str = s.ended_at.strftime("%H:%M") if s.ended_at else "진행중"
            dur = s.duration_minutes or 0
            total_minutes += dur
            lines.append(f"  {start_str} ~ {end_str} ({dur}분)")
        lines.append(f"  합계: {len(sleeps)}회, 총 {total_minutes}분 ({round(total_minutes/60, 1)}시간)")
    else:
        lines.append("  기록 없음")

    lines.append("")
    lines.append("배변 기록:")
    if diapers:
        type_map = {"pee": "소변", "poo": "대변", "both": "소변+대변"}
        for d in diapers:
            time_str = d.recorded_at.strftime("%H:%M")
            type_label = type_map.get(d.diaper_type.value, d.diaper_type.value)
            color = f"색상:{d.stool_color.value}" if d.stool_color else ""
            state = f"상태:{d.stool_state.value}" if d.stool_state else ""
            detail = ", ".join(filter(None, [color, state]))
            detail_str = f" ({detail})" if detail else ""
            lines.append(f"  {time_str} - {type_label}{detail_str}")
        lines.append(f"  합계: {len(diapers)}회")
    else:
        lines.append("  기록 없음")

    lines.append("")
    lines.append("놀이 기록:")
    if plays:
        total_play = 0
        for p in plays:
            start_str = p.started_at.strftime("%H:%M")
            dur = p.duration_minutes or 0
            total_play += dur
            lines.append(f"  {start_str} - {p.play_type} ({dur}분)")
        lines.append(f"  합계: {len(plays)}회, 총 {total_play}분")
    else:
        lines.append("  기록 없음")

    return "\n".join(lines)


def build_chat_context(baby: Baby) -> str:
    return (
        f"현재 상담 중인 아기 정보: {baby.name}, "
        f"생후 {baby.age_days}일 ({baby.age_months}개월)"
    )
