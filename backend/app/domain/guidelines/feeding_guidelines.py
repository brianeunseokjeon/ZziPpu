"""
영유아 수유 가이드.

출처:
- AAP Bright Futures 4판 (2024) - Feeding & Nutrition
- AAP Breastfeeding Recommendation (2022, 2024 reaffirmed) — 6개월 완전모유수유 권장
- 대한소아청소년과학회 영유아 영양 권고
- WHO 보완식 가이드 (이유식 6개월 시작)

요약:
- 모유: 6개월까지 완전모유수유 권장, 12-24개월까지 보완식과 병행
- 분유: 0-3개월 150-200 ml/kg/day, 4-6개월부터 1회량 증가/횟수 감소
- 비타민 D 400IU/day (모유수유 시 출생 후부터, 분유 1L 미만이면 추가)
- 6개월부터 이유식 시작, 12개월부터 생우유 가능
"""
from dataclasses import dataclass


@dataclass
class FeedingGuideline:
    amount_ml_range: tuple[int, int]        # 분유 1회량 (모유는 시간으로 측정)
    interval_hours: tuple[float, float]     # 수유 간격
    daily_count_range: tuple[int, int]      # 하루 수유 횟수
    per_kg_ml: int                          # 분유 하루 총량 (체중당 ml)
    breast_minutes_per_session: tuple[int, int]  # 모유 1회 수유 시간 (분)


# AAP 권고:
#   - 0-1개월: 분유 30-60ml × 2-3시간 (하루 8-12회), 모유 시 10-15분/측 × 8-12회
#   - 1-2개월: 분유 60-120ml × 2.5-3.5시간 (하루 7-10회)
#   - 2-4개월: 분유 90-150ml × 3-4시간 (하루 6-8회)
#   - 4-6개월: 분유 120-180ml × 3.5-5시간 (하루 5-6회), 이유식 도입 검토
#   - 6-9개월: 분유 180-210ml × 4-5시간 + 이유식 1-2회
#   - 9-12개월: 분유 180-210ml × 4-5시간 + 이유식 2-3회
#   - 12개월+: 생우유 480-720ml/day + 일반식
FEEDING_GUIDELINES: dict[tuple[int, int], FeedingGuideline] = {
    (0, 1): FeedingGuideline(
        amount_ml_range=(30, 60),
        interval_hours=(2.0, 3.0),
        daily_count_range=(8, 12),
        per_kg_ml=160,  # AAP: 150-200 ml/kg/day
        breast_minutes_per_session=(10, 15),
    ),
    (1, 2): FeedingGuideline(
        amount_ml_range=(60, 120),
        interval_hours=(2.5, 3.5),
        daily_count_range=(7, 10),
        per_kg_ml=150,
        breast_minutes_per_session=(10, 20),
    ),
    (2, 4): FeedingGuideline(
        amount_ml_range=(90, 150),
        interval_hours=(3.0, 4.0),
        daily_count_range=(6, 8),
        per_kg_ml=140,
        breast_minutes_per_session=(10, 20),
    ),
    (4, 6): FeedingGuideline(
        amount_ml_range=(120, 180),
        interval_hours=(3.5, 5.0),
        daily_count_range=(5, 6),
        per_kg_ml=130,
        breast_minutes_per_session=(10, 20),
    ),
    (6, 9): FeedingGuideline(
        amount_ml_range=(180, 210),
        interval_hours=(4.0, 5.0),
        daily_count_range=(4, 5),
        per_kg_ml=120,
        breast_minutes_per_session=(10, 15),
    ),
    (9, 12): FeedingGuideline(
        amount_ml_range=(180, 210),
        interval_hours=(4.0, 5.0),
        daily_count_range=(3, 4),
        per_kg_ml=110,
        breast_minutes_per_session=(10, 15),
    ),
    (12, 999): FeedingGuideline(
        amount_ml_range=(180, 240),  # 12개월부터는 생우유 가능 (분유 대신)
        interval_hours=(4.0, 6.0),
        daily_count_range=(3, 4),
        per_kg_ml=100,
        breast_minutes_per_session=(10, 15),
    ),
}


def get_feeding_guideline(age_months: int) -> FeedingGuideline:
    for (start, end), guideline in FEEDING_GUIDELINES.items():
        if start <= age_months < end:
            return guideline
    return FEEDING_GUIDELINES[(12, 999)]
