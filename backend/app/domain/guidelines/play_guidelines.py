from dataclasses import dataclass


@dataclass
class PlayGuideline:
    tummy_time_minutes: int
    tummy_time_sessions: int
    recommended_activities: list[str]


PLAY_GUIDELINES: dict[tuple[int, int], PlayGuideline] = {
    (0, 1): PlayGuideline(
        tummy_time_minutes=5,
        tummy_time_sessions=2,
        recommended_activities=["tummy_time", "gentle_massage", "eye_contact"],
    ),
    (1, 3): PlayGuideline(
        tummy_time_minutes=10,
        tummy_time_sessions=3,
        recommended_activities=["tummy_time", "gentle_massage", "singing", "colorful_toys"],
    ),
    (3, 6): PlayGuideline(
        tummy_time_minutes=20,
        tummy_time_sessions=4,
        recommended_activities=["tummy_time", "floor_play", "rattles", "mirrors", "singing"],
    ),
    (6, 9): PlayGuideline(
        tummy_time_minutes=30,
        tummy_time_sessions=4,
        recommended_activities=["sitting_support", "floor_play", "soft_blocks", "peek_a_boo"],
    ),
    (9, 12): PlayGuideline(
        tummy_time_minutes=30,
        tummy_time_sessions=4,
        recommended_activities=["crawling", "pulling_up", "shape_sorters", "stacking_toys"],
    ),
    (12, 999): PlayGuideline(
        tummy_time_minutes=30,
        tummy_time_sessions=3,
        recommended_activities=["walking", "push_toys", "simple_puzzles", "outdoor_play"],
    ),
}


def get_play_guideline(age_months: int) -> PlayGuideline:
    for (start, end), guideline in PLAY_GUIDELINES.items():
        if start <= age_months < end:
            return guideline
    return PLAY_GUIDELINES[(12, 999)]
