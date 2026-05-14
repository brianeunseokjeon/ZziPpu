from dataclasses import dataclass


@dataclass
class DiaperGuideline:
    min_wet_per_day: int
    poo_range: tuple[int, int]
    alert_colors: list[str]


DIAPER_GUIDELINES: dict[tuple[int, int], DiaperGuideline] = {
    (0, 1): DiaperGuideline(
        min_wet_per_day=1,
        poo_range=(1, 8),
        alert_colors=["black", "red", "white"],
    ),
    (1, 2): DiaperGuideline(
        min_wet_per_day=6,
        poo_range=(1, 6),
        alert_colors=["black", "red", "white"],
    ),
    (2, 6): DiaperGuideline(
        min_wet_per_day=6,
        poo_range=(0, 4),
        alert_colors=["black", "red", "white"],
    ),
    (6, 12): DiaperGuideline(
        min_wet_per_day=4,
        poo_range=(1, 3),
        alert_colors=["black", "red", "white"],
    ),
    (12, 999): DiaperGuideline(
        min_wet_per_day=4,
        poo_range=(1, 3),
        alert_colors=["black", "red", "white"],
    ),
}


def get_diaper_guideline(age_months: int) -> DiaperGuideline:
    for (start, end), guideline in DIAPER_GUIDELINES.items():
        if start <= age_months < end:
            return guideline
    return DIAPER_GUIDELINES[(12, 999)]
