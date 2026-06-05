from datetime import date, datetime, timedelta, timezone

from app.domain.entities.baby import Baby
from app.domain.entities.diaper import DiaperRecord
from app.domain.entities.feeding import Feeding
from app.domain.entities.play_record import PlayRecord
from app.domain.entities.sleep_record import SleepRecord
from app.domain.guidelines.developmental_milestones import get_stage_for_age_days
from app.domain.value_objects.feeding_type import FeedingType

_KST = timezone(timedelta(hours=9))


def _kst_hhmm(dt: datetime | None) -> str:
    """저장은 naive/aware UTC. AI 컨텍스트엔 KST 'HH:MM' 으로 표기."""
    if dt is None:
        return ""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(_KST).strftime("%H:%M")


def _get_developmental_milestones(age_days: int) -> str:
    """
    K-DST 6영역 + 부모 행동 + 위험 신호.
    단일 출처: developmental_milestones.DEVELOPMENT_STAGES — AI 채팅과 발달 가이드 페이지가 공유.
    """
    s = get_stage_for_age_days(age_days)

    def _line(label: str, items: list[str]) -> str:
        return f"- {label}: " + (", ".join(items) if items else "(해당 없음)")

    lines = [
        f"【발달 이정표 ({s.label}, K-DST 기준)】",
        f"- 요약: {s.summary}",
        _line("대근육", s.gross_motor),
        _line("소근육", s.fine_motor),
        _line("인지", s.cognition),
        _line("언어", s.language),
        _line("사회성", s.social),
        _line("자조", s.self_care),
        f"- 수유: {s.feeding_summary}",
        f"- 수면: {s.sleep_summary}",
        f"- 놀이: {s.play_summary}",
    ]
    if s.parent_actions:
        lines.append("【이 시기 부모 행동】")
        for a in s.parent_actions[:5]:
            lines.append(f"- [{a.priority}] {a.icon} {a.title}: {a.detail} (출처: {a.source})")
    if s.warning_signs:
        lines.append("【위험 신호 — 이 중 하나라도 보이면 즉시 내원】")
        for w in s.warning_signs:
            lines.append(f"- {w}")
    return "\n".join(lines)


def build_daily_context(
    baby: Baby,
    feedings: list[Feeding],
    sleeps: list[SleepRecord],
    diapers: list[DiaperRecord],
    plays: list[PlayRecord],
    review_date: date | None = None,
) -> str:
    # review_date 가 주어지면 그날 기준 나이로 표기 (없으면 오늘 기준).
    age_days = baby.age_days_at(review_date) if review_date else baby.age_days
    age_months = baby.age_months_at(review_date) if review_date else baby.age_months
    lines = [
        "아기 정보:",
        f"  이름: {baby.name}",
        f"  생후: {age_days}일 ({age_months}개월)",
        "",
        "수유 기록:",
    ]

    if feedings:
        for f in feedings:
            time_str = _kst_hhmm(f.started_at)
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
            start_str = _kst_hhmm(s.started_at)
            end_str = _kst_hhmm(s.ended_at) if s.ended_at else "진행중"
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
            time_str = _kst_hhmm(d.recorded_at)
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
            start_str = _kst_hhmm(p.started_at)
            dur = p.duration_minutes or 0
            total_play += dur
            lines.append(f"  {start_str} - {p.play_type} ({dur}분)")
        lines.append(f"  합계: {len(plays)}회, 총 {total_play}분")
    else:
        lines.append("  기록 없음")

    return "\n".join(lines)


def build_chat_context(baby: Baby, chat_date: date) -> str:
    # 상담 기준 날짜의 생후 일수/개월로 컨텍스트 구성 (헤더에서 과거 날짜 선택 시 그날 기준).
    age_days = baby.age_days_at(chat_date)
    age_months = baby.age_months_at(chat_date)
    milestones = _get_developmental_milestones(age_days)
    date_str = chat_date.strftime("%Y년 %m월 %d일")
    return (
        f"【현재 상담 중인 아기 정보】\n"
        f"이름: {baby.name}\n"
        f"상담 기준 날짜: {date_str}\n"
        f"생후: {age_days}일 ({age_months}개월)\n\n"
        f"{milestones}\n\n"
        f"※ 반드시 이 아기의 나이(생후 {age_days}일, {date_str} 기준)에 맞는 조언을 해주세요."
    )
