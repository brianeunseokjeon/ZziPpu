"""
영유아 수면 가이드.

출처:
- AASM (American Academy of Sleep Medicine) Pediatric Sleep Duration Consensus
  (2016, AAP 공식 endorsement, 2024 reaffirmed)
- AAP Bright Futures 4판 (2024) / AAP Safe Sleep Recommendations (2022)
- 대한소아청소년과학회 영유아 수면 권고
"""
from dataclasses import dataclass


@dataclass
class SleepGuideline:
    total_hours_range: tuple[float, float]   # 24시간 총 수면 (낮잠 포함)
    nap_count: tuple[int, int]               # 낮잠 횟수
    night_sleep_hours: tuple[float, float]   # 야간 연속 수면 가능 시간


# AASM 권고(2016, 2024 재확인):
#   - 0-3개월: 공식 권고 미설정 (개인차 큼). 통상 14-17시간 인용.
#   - 4-12개월: 12-16시간 (낮잠 포함)
#   - 1-2세: 11-14시간
#   - 3-5세: 10-13시간
# 모유수유 신생아는 첫 5-6주간 4-5시간 이상 연속 수면 피하기 (AAP).
SLEEP_GUIDELINES: dict[tuple[int, int], SleepGuideline] = {
    (0, 1): SleepGuideline(
        total_hours_range=(14.0, 17.0),
        nap_count=(4, 6),
        night_sleep_hours=(3.0, 4.0),  # 첫 6주는 4-5시간 이상 자지 않게
    ),
    (1, 3): SleepGuideline(
        total_hours_range=(14.0, 17.0),
        nap_count=(3, 5),
        night_sleep_hours=(5.0, 8.0),
    ),
    (3, 6): SleepGuideline(
        total_hours_range=(12.0, 16.0),
        nap_count=(3, 4),
        night_sleep_hours=(8.0, 10.0),
    ),
    (6, 9): SleepGuideline(
        total_hours_range=(12.0, 16.0),
        nap_count=(2, 3),
        night_sleep_hours=(9.0, 11.0),
    ),
    (9, 12): SleepGuideline(
        total_hours_range=(12.0, 16.0),
        nap_count=(2, 3),
        night_sleep_hours=(10.0, 12.0),
    ),
    (12, 24): SleepGuideline(
        total_hours_range=(11.0, 14.0),
        nap_count=(1, 2),
        night_sleep_hours=(10.0, 12.0),
    ),
    (24, 999): SleepGuideline(
        total_hours_range=(10.0, 13.0),
        nap_count=(0, 1),
        night_sleep_hours=(10.0, 12.0),
    ),
}


def get_sleep_guideline(age_months: int) -> SleepGuideline:
    for (start, end), guideline in SLEEP_GUIDELINES.items():
        if start <= age_months < end:
            return guideline
    return SLEEP_GUIDELINES[(24, 999)]
