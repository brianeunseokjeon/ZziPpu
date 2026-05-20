"""
일일 AI 리뷰 생성 프롬프트.

출처 우선순위:
1. 대한소아청소년과학회 + 질병관리청 표준예방접종/영유아건강검진
2. AAP Bright Futures 4판 (2024)
"""
from app.domain.guidelines.developmental_milestones import get_stage_for_age_days
from app.domain.guidelines.guideline_references import (
    AMERICAN_AUTHORITIES,
    GUIDELINE_LAST_UPDATED,
    KOREAN_AUTHORITIES,
)


def _get_age_stage(age_days: int) -> str:
    """
    K-DST 6영역 + 부모 행동 + 위험 신호를 텍스트로 직렬화.
    단일 출처: developmental_milestones.DEVELOPMENT_STAGES (발달 가이드 페이지와 공유).
    """
    s = get_stage_for_age_days(age_days)

    def _list(items: list[str], sep: str = ", ") -> str:
        return sep.join(items) if items else "(해당 없음)"

    sections = [
        f"{s.label}",
        f"  요약: {s.summary}",
        f"  대근육: {_list(s.gross_motor)}",
        f"  소근육: {_list(s.fine_motor)}",
        f"  인지: {_list(s.cognition)}",
        f"  언어: {_list(s.language)}",
        f"  사회성: {_list(s.social)}",
        f"  자조: {_list(s.self_care)}",
        f"  수유: {s.feeding_summary}",
        f"  수면: {s.sleep_summary}",
        f"  놀이: {s.play_summary}",
    ]
    if s.parent_actions:
        sections.append("  이 시기 부모 행동:")
        for a in s.parent_actions[:5]:
            sections.append(f"    [{a.priority}] {a.icon} {a.title} — {a.detail} (출처: {a.source})")
    if s.warning_signs:
        sections.append("  위험 신호 (이 중 하나라도 보이면 즉시 내원):")
        for w in s.warning_signs:
            sections.append(f"    · {w}")
    return "\n".join(sections)


def build_daily_review_prompt(context: str, age_days: int = 0) -> str:
    age_stage = _get_age_stage(age_days)
    sources = ", ".join(KOREAN_AUTHORITIES[:2] + AMERICAN_AUTHORITIES[:2])
    return f"""당신은 소아청소년과 전문의입니다. 다음 가이드라인을 우선순위로 따르세요:
{sources}
(마지막 검토: {GUIDELINE_LAST_UPDATED})

생후 {age_days}일 아기의 오늘 육아 기록을 분석합니다.

【아기 발달 단계 참고 (출처 기반)】
{age_stage}

【오늘의 기록】
{context}

위 데이터를 바탕으로 아래 JSON 형식으로 오늘의 육아 리뷰를 작성하세요.
각 항목은 구체적이며 이 아기의 나이(생후 {age_days}일)에 맞는 내용이어야 합니다.

{{
  "feeding_analysis": "오늘 수유 패턴 분석 (양·횟수·간격, 월령 가이드 대비 적절성, 출처 인용)",
  "sleep_analysis": "오늘 수면 분석 (총 수면 시간, 패턴, AASM 권장치 대비)",
  "diaper_analysis": "오늘 배변 분석 (횟수·색상·상태 이상 여부, AAP Stool Color 기준)",
  "play_analysis": "오늘 놀이/터미타임 분석 (종류·시간, 발달 적절성)",
  "overall_assessment": "오늘 하루 전반적인 요약 (2~3문장, 따뜻하고 공감하는 어조)",
  "positives": ["오늘 잘 한 점 또는 좋은 신호 (구체적으로, 1~3개)"],
  "considerations": ["앞으로 고려하면 좋을 것들 (월령 맞춤 팁, 1~3개)"],
  "concerns": ["걱정되거나 주의가 필요한 점 (없으면 빈 배열)"],
  "critical_warnings": ["즉시 병원 방문이 필요하거나 절대 하면 안 되는 것 (해당 없으면 반드시 빈 배열)"],
  "alerts": ["기타 주의 사항 (없으면 빈 배열)"],
  "recommendations": ["내일을 위한 추천 사항 (1~3개)"]
}}

【엄수 사항】
- critical_warnings는 실제로 위험한 상황이 아니면 반드시 빈 배열 []로 반환할 것
- concerns는 약한 주의사항, critical_warnings는 즉각 의료 처치가 필요한 수준만
- 가이드라인 인용 시 출처를 짧게 명시 (예: "AAP 권고에 따라…")
- JSON만 반환하고 다른 텍스트(앞뒤 설명, ``` 코드블록 등) 포함 금지
"""
