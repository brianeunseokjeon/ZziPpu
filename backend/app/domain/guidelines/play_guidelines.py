"""
영유아 놀이/터미타임 가이드.

출처:
- AAP Bright Futures 4판 (2024) - Play & Development
- AAP Tummy Time Recommendation (출생 직후부터, 깨어있는 동안 supervised)
- 대한소아청소년과학회 K-DST (대근육·소근육·인지·언어·사회성·자조)
- AAP Media Use Guidelines: 18개월 미만 화상 통화 외 영상 금지
"""
from dataclasses import dataclass


@dataclass
class PlayGuideline:
    tummy_time_minutes: int           # 하루 누적 터미타임 목표 (분)
    tummy_time_sessions: int          # 하루 권장 세션 수
    recommended_activities: list[str] # 이 시기 권장 놀이
    screen_time_minutes: int          # 권장 화면 노출 한도 (분/일, 화상통화 제외)


# AAP 권고:
#   - 0-3개월: 출생 직후부터 supervised tummy time. 처음엔 2-3분씩, 점차 늘려 3개월에 하루 누적 15-30분
#   - 3-6개월: 하루 누적 30-60분 (뒤집기 도움)
#   - 6-12개월: 자유롭게 바닥놀이, 기기 연습
#   - 18개월 미만: 화상 통화 외 화면 노출 금지 (AAP Media Use Guidelines)
#   - 18-24개월: 부모와 함께 보는 양질의 영상 최대 1시간/일
PLAY_GUIDELINES: dict[tuple[int, int], PlayGuideline] = {
    (0, 1): PlayGuideline(
        tummy_time_minutes=10,           # 2-3분 × 3-4회
        tummy_time_sessions=3,
        recommended_activities=[
            "tummy_time",        # 깨어있을 때 짧게
            "gentle_massage",    # 부드러운 마사지
            "eye_contact",       # 얼굴 응시
            "talking",           # 말 걸기 (언어 자극)
        ],
        screen_time_minutes=0,
    ),
    (1, 3): PlayGuideline(
        tummy_time_minutes=20,
        tummy_time_sessions=3,
        recommended_activities=[
            "tummy_time",
            "gentle_massage",
            "singing",
            "high_contrast_cards",  # 흑백 카드 (시각 발달)
            "rattle_track",          # 딸랑이 따라 보기
        ],
        screen_time_minutes=0,
    ),
    (3, 6): PlayGuideline(
        tummy_time_minutes=45,
        tummy_time_sessions=4,
        recommended_activities=[
            "tummy_time",
            "floor_play",
            "rattles",
            "baby_mirror",      # 거울 놀이 (자기 인식 시작)
            "singing_with_gestures",  # 손동작 노래
        ],
        screen_time_minutes=0,
    ),
    (6, 9): PlayGuideline(
        tummy_time_minutes=60,
        tummy_time_sessions=4,
        recommended_activities=[
            "sitting_support",     # 앉기 연습
            "floor_play",
            "soft_blocks",
            "peek_a_boo",          # 까꿍 놀이 (대상영속성)
            "reading_picture_books",
        ],
        screen_time_minutes=0,
    ),
    (9, 12): PlayGuideline(
        tummy_time_minutes=60,
        tummy_time_sessions=4,
        recommended_activities=[
            "crawling",
            "pulling_up",
            "shape_sorters",
            "stacking_cups",
            "finger_food_practice",  # 손가락 음식 (자조 능력)
            "reading",
        ],
        screen_time_minutes=0,
    ),
    (12, 18): PlayGuideline(
        tummy_time_minutes=30,   # 이 시기엔 터미타임 대신 자유 활동 위주
        tummy_time_sessions=3,
        recommended_activities=[
            "walking_practice",
            "push_toys",
            "simple_puzzles",
            "imitation_play",     # 따라 하기 놀이
            "outdoor_play",
            "reading",
        ],
        screen_time_minutes=0,    # 18개월 미만 화상통화 외 영상 금지 (AAP)
    ),
    (18, 999): PlayGuideline(
        tummy_time_minutes=0,    # 더 이상 별도 터미타임 불필요
        tummy_time_sessions=0,
        recommended_activities=[
            "walking_running",
            "stacking_blocks",
            "drawing_scribbling",
            "imaginative_play",
            "outdoor_play",
            "reading",
        ],
        screen_time_minutes=60,  # 18-24개월: 양질 영상 최대 1시간 (부모 동반)
    ),
}


def get_play_guideline(age_months: int) -> PlayGuideline:
    for (start, end), guideline in PLAY_GUIDELINES.items():
        if start <= age_months < end:
            return guideline
    return PLAY_GUIDELINES[(18, 999)]
