from app.domain.entities.baby import Baby
from app.domain.entities.feeding import Feeding
from app.domain.entities.sleep_record import SleepRecord
from app.domain.entities.diaper import DiaperRecord
from app.domain.entities.play_record import PlayRecord
from app.domain.value_objects.feeding_type import FeedingType


def _get_developmental_milestones(age_days: int) -> str:
    """
    K-DST 6개 영역(대근육·소근육·인지·언어·사회성·자조) 기준 발달 이정표.
    출처: 보건복지부 K-DST(2024), AAP Bright Futures 4판(2024), 대한소아청소년과학회.
    """
    if age_days <= 28:
        return (
            "【발달 이정표 (신생아기, K-DST 기준)】\n"
            "- 대근육: 굴곡 자세, 짧은 시간 머리 들기\n"
            "- 인지/사회성: 빛과 소리에 반응, 얼굴 응시 시작\n"
            "- 언어: 울음으로 욕구 표현\n"
            "【위험 신호 (즉시 내원)】\n"
            "- 직장 체온 38℃ 이상 발열 (3개월 미만은 무조건 응급)\n"
            "- 황달이 2주 이상 지속되거나 더 진해짐\n"
            "- 수유 거부 8시간 이상, 처짐, 청색증\n"
            "【절대 금지】 엎어 재우기(SIDS), 흔들기(SBS), 베개/이불"
        )
    elif age_days <= 60:
        return (
            "【발달 이정표 (생후 1~2개월)】\n"
            "- 대근육: 엎드려서 잠시 머리 들기\n"
            "- 인지/사회성: 사회적 미소 시작 (4~6주)\n"
            "- 언어: 부드러운 발성 시작 (cooing)\n"
            "- 자조: 수유 텀 점차 길어짐\n"
            "【위험 신호】 38℃ 이상 발열, 수유 거부, 호흡 곤란\n"
            "【권고】 비타민 D 400IU/일 (모유수유 시 출생 직후부터, AAP)"
        )
    elif age_days <= 90:
        return (
            "【발달 이정표 (생후 2~3개월)】\n"
            "- 대근육: 목 가누기 시작, 엎드려 가슴 들기\n"
            "- 소근육: 손을 펴서 가운데로 모으기\n"
            "- 사회성: 사람을 향해 웃음, 얼굴 인식\n"
            "- 터미타임: 하루 누적 15~30분 (3~4회 분산)\n"
            "【절대 금지】 4개월 이전 이유식, 꿀, 흔들기\n"
            "【권고】 비타민 D 400IU/일 지속"
        )
    elif age_days <= 180:
        return (
            "【발달 이정표 (생후 3~6개월)】\n"
            "- 대근육: 목 완전히 가눔(4개월), 뒤집기(4~6개월)\n"
            "- 소근육: 물건 잡고 입으로 가져가기\n"
            "- 언어: 옹알이 활발, 다양한 자음 시도\n"
            "- 사회성: 자기 이름에 반응, 낯선 사람 인식 시작\n"
            "【이유식】 6개월 시작 권장 (AAP·대한소아과학회). 4개월 이전 금지\n"
            "【주의】 뒤집기 시작 → 침대 낙상 위험. 꿀 금지 지속"
        )
    elif age_days <= 270:
        return (
            "【발달 이정표 (생후 6~9개월)】\n"
            "- 대근육: 혼자 앉기(6~7개월), 기기 시작\n"
            "- 소근육: 손에서 손으로 물건 옮기기\n"
            "- 인지: 대상영속성(까꿍 놀이 반응)\n"
            "- 사회성: 낯가림 시작\n"
            "- 자조: 이유식 시작, 컵 사용 연습\n"
            "【권고】 모유수유 시 철분 1mg/kg/day (AAP, 이유식 철분 강화로 보완)\n"
            "【주의】 질식 위험 식품 금지 (견과, 통포도, 사탕, 생당근)"
        )
    elif age_days <= 365:
        return (
            "【발달 이정표 (생후 9~12개월)】\n"
            "- 대근육: 잡고 서기, 첫 걸음 준비\n"
            "- 소근육: 손가락 집기(pincer grasp)\n"
            "- 언어: '엄마/아빠' 같은 단어 1~2개 시도\n"
            "- 사회성: 손 흔들기, 안녕 표현\n"
            "- 자조: 손가락 음식 스스로 먹기\n"
            "【절대 금지】 꿀, 생우유(12개월 미만), 보행기\n"
            "【권고】 12개월 검진(K-DST 1차 발달선별검사) 예약"
        )
    else:
        months = age_days // 30
        return (
            f"【발달 이정표 (생후 {months}개월, 유아기 초기)】\n"
            "- 대근육: 걷기, 계단 잡고 오르내리기\n"
            "- 언어: 18개월 어휘 10~50개, 24개월 두 단어 조합\n"
            "- 사회성: 따라 하기, 평행 놀이\n"
            "- 자조: 숟가락 사용, 옷 벗기 도움 받기\n"
            "【권고】 12개월 이후 생우유 480~720ml/일 가능, 일반식 전환\n"
            "【화면 노출】 18개월 미만 화상통화 외 영상 금지 (AAP)\n"
            "【주의】 작은 물건 삼킴(4cm 미만 위험), 보행기 금지"
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
