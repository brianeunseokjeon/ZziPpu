"""
배변(기저귀) 가이드.

출처:
- AAP (HealthyChildren.org) Diaper Output 권고
- 대한소아청소년과학회 영유아 정상 배변 범위
- AAP Stool Color Card (담관폐쇄증 조기 발견)

키 = (시작 일수, 끝 일수). 신생아기는 '일수' 단위로 더 정밀하게 구분.
"""
from dataclasses import dataclass


@dataclass
class DiaperGuideline:
    min_wet_per_day: int          # 최소 정상 wet 기저귀 횟수/일
    poo_range: tuple[int, int]    # 정상 대변 횟수/일 (최소, 최대)
    alert_colors: list[str]       # 즉시 병원 상담 필요 색상


# AAP HealthyChildren 권고:
#   1일차: wet 1회 / poo 1회 (태변)
#   2일차: wet 2회 / poo 2-3회 (태변 끝)
#   3일차: wet 3회 / poo 노란 변으로 전환
#   4-5일차: wet 4-6회 / poo 변동성 있음
#   1주~1개월: wet 6-8회 / poo 3-12회 (모유수유는 매끼 가능)
#   1-6개월: wet 6-8회 / poo 1-7회 (이후 줄어들 수 있음, 모유수유는 1주 1회도 가능)
#   6-12개월: wet 4-6회 / poo 1-3회
ALERT_COLORS = ["black", "red", "white"]  # 흑변=상부소화관 출혈, 적변=하부출혈, 백변=담관폐쇄증

DIAPER_GUIDELINES: dict[tuple[int, int], DiaperGuideline] = {
    # 일수 단위 (신생아 첫 며칠은 wet 기저귀 수가 매일 다름)
    # 키 의미: 'days'가 [start, end) 범위. age_days로 조회.
    (0, 5): DiaperGuideline(
        min_wet_per_day=3,
        poo_range=(1, 8),
        alert_colors=ALERT_COLORS,
    ),
    (5, 30): DiaperGuideline(
        min_wet_per_day=6,
        poo_range=(3, 12),
        alert_colors=ALERT_COLORS,
    ),
    # 1개월 이후는 월령 단위 (30일=1개월 근사)
    (30, 60): DiaperGuideline(
        min_wet_per_day=6,
        poo_range=(1, 8),
        alert_colors=ALERT_COLORS,
    ),
    (60, 180): DiaperGuideline(
        min_wet_per_day=6,
        poo_range=(1, 6),
        alert_colors=ALERT_COLORS,
    ),
    (180, 365): DiaperGuideline(
        min_wet_per_day=5,
        poo_range=(1, 4),
        alert_colors=ALERT_COLORS,
    ),
    (365, 99999): DiaperGuideline(
        min_wet_per_day=4,
        poo_range=(1, 3),
        alert_colors=ALERT_COLORS,
    ),
}


def get_diaper_guideline(age_days: int) -> DiaperGuideline:
    """age_days(생후 일수)로 조회. 신생아 첫 며칠을 정밀하게 다루기 위함."""
    for (start, end), guideline in DIAPER_GUIDELINES.items():
        if start <= age_days < end:
            return guideline
    return DIAPER_GUIDELINES[(365, 99999)]


# 하위 호환: 기존 코드가 month-based로 호출하는 경우
def get_diaper_guideline_by_months(age_months: int) -> DiaperGuideline:
    return get_diaper_guideline(age_months * 30)
