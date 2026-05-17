from app.domain.entities.baby import Baby
from app.domain.entities.feeding import Feeding
from app.domain.entities.sleep_record import SleepRecord
from app.domain.entities.diaper import DiaperRecord
from app.domain.entities.play_record import PlayRecord
from app.domain.value_objects.feeding_type import FeedingType


def _get_developmental_milestones(age_days: int) -> str:
    if age_days <= 28:
        return (
            "【이 시기 발달 이정표 (신생아기)】\n"
            "- 빛과 소리에 반응, 얼굴 응시 시작\n"
            "- 수유 시 강한 흡철 반사\n"
            "【이 시기 특별 주의사항】\n"
            "- 황달(피부/눈 노랗게 변함): 2주 이상 지속 시 즉시 내원\n"
            "- 엎어 재우기 절대 금지 (영아돌연사 위험)\n"
            "- 발열(38도 이상): 즉시 응급실"
        )
    elif age_days <= 60:
        return (
            "【이 시기 발달 이정표 (생후 1~2개월)】\n"
            "- 사회적 미소 시작 (4~6주)\n"
            "- 소리 나는 방향으로 고개 돌리기\n"
            "- 수유 후 트림 필수\n"
            "【이 시기 특별 주의사항】\n"
            "- 엎어 재우기 절대 금지\n"
            "- 고열(38도 이상), 수유 거부: 즉시 내원\n"
            "- 비타민D 400IU 매일 보충 권장"
        )
    elif age_days <= 90:
        return (
            "【이 시기 발달 이정표 (생후 2~3개월)】\n"
            "- 목 가누기 시작, 옹알이 활발\n"
            "- 사람 얼굴 인식, 웃음 반응\n"
            "- 터미타임 하루 30분 목표\n"
            "【이 시기 특별 주의사항】\n"
            "- 아직 이유식 금지 (4개월 이전)\n"
            "- 흔들기 금지 (흔들린아이증후군)\n"
            "- 비타민D 400IU 매일 보충"
        )
    elif age_days <= 180:
        return (
            "【이 시기 발달 이정표 (생후 3~6개월)】\n"
            "- 뒤집기 시작(4~5개월), 목 완전히 가눔\n"
            "- 손으로 물건 잡기, 옹알이 더 활발\n"
            "- 이유식: 4~6개월 사이 시작 검토\n"
            "【이 시기 특별 주의사항】\n"
            "- 꿀 절대 금지 (보툴리누스 독소)\n"
            "- 낙상 주의 (뒤집기 시작으로 침대에서 떨어질 수 있음)\n"
            "- 이유식 시작 전 소아과 상담 권장"
        )
    elif age_days <= 270:
        return (
            "【이 시기 발달 이정표 (생후 6~9개월)】\n"
            "- 혼자 앉기(6~7개월), 이유식 진행 중\n"
            "- 낯가림 시작, 부모 인식 확실\n"
            "- 기기 시작 준비\n"
            "【이 시기 특별 주의사항】\n"
            "- 꿀 절대 금지\n"
            "- 이유식: 알레르기 유발 식품 천천히 도입\n"
            "- 철분 보충 확인 (이유식 철분 강화 필요)\n"
            "- 낙상 방지: 혼자 앉힐 때 옆에서 지켜봐야"
        )
    else:
        return (
            f"【이 시기 발달 이정표 (생후 {age_days//30}개월)】\n"
            "- 기기, 잡고 서기 시작\n"
            "- 손가락으로 집기, 옹알이로 의사소통\n"
            "- 이유식 → 유아식 전환 준비\n"
            "【이 시기 특별 주의사항】\n"
            "- 작은 물건 삼킴 주의 (기도 막힘)\n"
            "- 꿀 12개월 미만 절대 금지\n"
            "- 보행기 사용 권장하지 않음 (근육 발달 저해)"
        )


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
    milestones = _get_developmental_milestones(baby.age_days)
    return (
        f"【현재 상담 중인 아기 정보】\n"
        f"이름: {baby.name}\n"
        f"생후: {baby.age_days}일 ({baby.age_months}개월)\n\n"
        f"{milestones}\n\n"
        f"※ 반드시 이 아기의 나이(생후 {baby.age_days}일)에 맞는 조언을 해주세요."
    )
