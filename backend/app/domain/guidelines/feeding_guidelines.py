from dataclasses import dataclass


@dataclass
class FeedingGuideline:
    amount_ml_range: tuple[int, int]
    interval_hours: tuple[float, float]
    daily_count_range: tuple[int, int]
    per_kg_ml: int


FEEDING_GUIDELINES: dict[tuple[int, int], FeedingGuideline] = {
    (0, 1): FeedingGuideline(
        amount_ml_range=(30, 60),
        interval_hours=(2.0, 3.0),
        daily_count_range=(8, 12),
        per_kg_ml=150,
    ),
    (1, 2): FeedingGuideline(
        amount_ml_range=(60, 90),
        interval_hours=(2.5, 3.5),
        daily_count_range=(7, 10),
        per_kg_ml=150,
    ),
    (2, 4): FeedingGuideline(
        amount_ml_range=(90, 120),
        interval_hours=(3.0, 4.0),
        daily_count_range=(6, 8),
        per_kg_ml=140,
    ),
    (4, 6): FeedingGuideline(
        amount_ml_range=(120, 180),
        interval_hours=(3.5, 4.5),
        daily_count_range=(5, 6),
        per_kg_ml=130,
    ),
    (6, 9): FeedingGuideline(
        amount_ml_range=(180, 210),
        interval_hours=(4.0, 5.0),
        daily_count_range=(4, 5),
        per_kg_ml=120,
    ),
    (9, 12): FeedingGuideline(
        amount_ml_range=(210, 240),
        interval_hours=(4.0, 5.0),
        daily_count_range=(3, 4),
        per_kg_ml=110,
    ),
    (12, 999): FeedingGuideline(
        amount_ml_range=(240, 360),
        interval_hours=(4.0, 6.0),
        daily_count_range=(3, 4),
        per_kg_ml=100,
    ),
}


def get_feeding_guideline(age_months: int) -> FeedingGuideline:
    for (start, end), guideline in FEEDING_GUIDELINES.items():
        if start <= age_months < end:
            return guideline
    return FEEDING_GUIDELINES[(12, 999)]
