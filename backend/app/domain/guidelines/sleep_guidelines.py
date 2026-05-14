from dataclasses import dataclass


@dataclass
class SleepGuideline:
    total_hours_range: tuple[float, float]
    nap_count: tuple[int, int]
    night_sleep_hours: tuple[float, float]


SLEEP_GUIDELINES: dict[tuple[int, int], SleepGuideline] = {
    (0, 1): SleepGuideline(
        total_hours_range=(16.0, 18.0),
        nap_count=(4, 6),
        night_sleep_hours=(8.0, 9.0),
    ),
    (1, 3): SleepGuideline(
        total_hours_range=(14.0, 17.0),
        nap_count=(3, 5),
        night_sleep_hours=(8.0, 10.0),
    ),
    (3, 6): SleepGuideline(
        total_hours_range=(14.0, 16.0),
        nap_count=(3, 4),
        night_sleep_hours=(9.0, 11.0),
    ),
    (6, 9): SleepGuideline(
        total_hours_range=(13.0, 15.0),
        nap_count=(2, 3),
        night_sleep_hours=(10.0, 12.0),
    ),
    (9, 12): SleepGuideline(
        total_hours_range=(12.0, 15.0),
        nap_count=(2, 3),
        night_sleep_hours=(10.0, 12.0),
    ),
    (12, 999): SleepGuideline(
        total_hours_range=(11.0, 14.0),
        nap_count=(1, 2),
        night_sleep_hours=(10.0, 12.0),
    ),
}


def get_sleep_guideline(age_months: int) -> SleepGuideline:
    for (start, end), guideline in SLEEP_GUIDELINES.items():
        if start <= age_months < end:
            return guideline
    return SLEEP_GUIDELINES[(12, 999)]
