from typing import TypedDict


class VaccineEntry(TypedDict):
    name: str
    dose: int
    offset_days: int      # 권장 접종 시점 (출생 후 일수)
    grace_days: int       # 권장일 이후 이만큼 지나야 "기한 초과"로 표시
    description: str


# 대한민국 표준예방접종 일정 — 질병관리청(KDCA) 예방접종도우미 / 대한소아청소년과학회 기준 (2026.05)
#
# offset_days = 권장 접종 시점 (출생일 = day 0 기준)
# grace_days  = 권장일이 지나도 이 기간 내에는 "기한 초과"로 간주하지 않음 (의학적 허용 윈도우)
#
# 예: BCG는 생후 4주(28일) 권장이며, 생후 3개월(약 90일)까지는 TST 없이 접종 가능 → grace 60일
#     일반적으로 1·2개월 백신은 약 30일, 추가접종(돌 이후)은 90일 이상의 유연한 윈도우
VACCINATION_SCHEDULE: list[VaccineEntry] = [
    # ── 신생아 ──────────────────────────────────────
    {"name": "BCG", "dose": 1, "offset_days": 28, "grace_days": 60, "description": "결핵 (생후 4주 이내 권장)"},
    {"name": "B형간염", "dose": 1, "offset_days": 0, "grace_days": 14, "description": "B형 간염 (출생 24시간 이내)"},
    {"name": "B형간염", "dose": 2, "offset_days": 30, "grace_days": 30, "description": "B형 간염 (생후 1개월)"},
    {"name": "B형간염", "dose": 3, "offset_days": 180, "grace_days": 60, "description": "B형 간염 (생후 6개월)"},

    # ── 2-6개월: 기초 접종 ─────────────────────────
    {"name": "DTaP", "dose": 1, "offset_days": 60, "grace_days": 30, "description": "디프테리아/파상풍/백일해 (2개월)"},
    {"name": "DTaP", "dose": 2, "offset_days": 120, "grace_days": 30, "description": "디프테리아/파상풍/백일해 (4개월)"},
    {"name": "DTaP", "dose": 3, "offset_days": 180, "grace_days": 30, "description": "디프테리아/파상풍/백일해 (6개월)"},
    {"name": "IPV", "dose": 1, "offset_days": 60, "grace_days": 30, "description": "폴리오 (2개월)"},
    {"name": "IPV", "dose": 2, "offset_days": 120, "grace_days": 30, "description": "폴리오 (4개월)"},
    {"name": "IPV", "dose": 3, "offset_days": 180, "grace_days": 60, "description": "폴리오 (6-18개월)"},
    {"name": "Hib", "dose": 1, "offset_days": 60, "grace_days": 30, "description": "뇌수막염 (2개월)"},
    {"name": "Hib", "dose": 2, "offset_days": 120, "grace_days": 30, "description": "뇌수막염 (4개월)"},
    {"name": "Hib", "dose": 3, "offset_days": 180, "grace_days": 30, "description": "뇌수막염 (6개월)"},
    {"name": "PCV", "dose": 1, "offset_days": 60, "grace_days": 30, "description": "폐렴구균 (2개월)"},
    {"name": "PCV", "dose": 2, "offset_days": 120, "grace_days": 30, "description": "폐렴구균 (4개월)"},
    {"name": "PCV", "dose": 3, "offset_days": 180, "grace_days": 30, "description": "폐렴구균 (6개월)"},
    {"name": "로타바이러스", "dose": 1, "offset_days": 60, "grace_days": 30, "description": "장염 경구 백신 (2개월)"},
    {"name": "로타바이러스", "dose": 2, "offset_days": 120, "grace_days": 30, "description": "장염 경구 백신 (4개월)"},
    {"name": "로타바이러스", "dose": 3, "offset_days": 180, "grace_days": 30, "description": "장염 경구 백신 (6개월, RV5에 해당)"},
    {"name": "수막구균", "dose": 1, "offset_days": 60, "grace_days": 365, "description": "수막구균 (선택접종, 생후 2개월~ 고위험군)"},

    # ── 12-18개월: 추가 접종 ───────────────────────
    {"name": "Hib", "dose": 4, "offset_days": 365, "grace_days": 90, "description": "뇌수막염 추가 (12-15개월)"},
    {"name": "PCV", "dose": 4, "offset_days": 365, "grace_days": 90, "description": "폐렴구균 추가 (12-15개월)"},
    {"name": "MMR", "dose": 1, "offset_days": 365, "grace_days": 90, "description": "홍역/유행성이하선염/풍진 (12-15개월)"},
    {"name": "수두", "dose": 1, "offset_days": 365, "grace_days": 90, "description": "수두 (12-15개월)"},
    {"name": "A형간염", "dose": 1, "offset_days": 365, "grace_days": 180, "description": "A형 간염 (12-23개월)"},
    {"name": "일본뇌염(불활화)", "dose": 1, "offset_days": 365, "grace_days": 180, "description": "일본뇌염 1차 (12-23개월)"},
    {"name": "일본뇌염(불활화)", "dose": 2, "offset_days": 395, "grace_days": 90, "description": "일본뇌염 2차 (1차 후 1개월)"},
    {"name": "DTaP", "dose": 4, "offset_days": 450, "grace_days": 90, "description": "디프테리아/파상풍/백일해 추가 (15-18개월)"},
    {"name": "A형간염", "dose": 2, "offset_days": 545, "grace_days": 180, "description": "A형 간염 2차 (1차 후 6개월)"},
    {"name": "일본뇌염(불활화)", "dose": 3, "offset_days": 730, "grace_days": 180, "description": "일본뇌염 3차 (2차 후 11개월)"},

    # ── 만 4-6세 ──────────────────────────────────
    {"name": "DTaP", "dose": 5, "offset_days": 1460, "grace_days": 365, "description": "디프테리아/파상풍/백일해 5차 (만 4-6세)"},
    {"name": "IPV", "dose": 4, "offset_days": 1460, "grace_days": 365, "description": "폴리오 4차 (만 4-6세)"},
    {"name": "MMR", "dose": 2, "offset_days": 1460, "grace_days": 365, "description": "MMR 2차 (만 4-6세)"},
    {"name": "일본뇌염(불활화)", "dose": 4, "offset_days": 2190, "grace_days": 365, "description": "일본뇌염 4차 (만 6세)"},

    # ── 만 11-12세 (청소년) ────────────────────────
    {"name": "Tdap/Td", "dose": 1, "offset_days": 4015, "grace_days": 730, "description": "파상풍/디프테리아/백일해 추가 (만 11-12세)"},
    {"name": "HPV", "dose": 1, "offset_days": 4015, "grace_days": 730, "description": "사람유두종바이러스 1차 (만 11-12세)"},
    {"name": "HPV", "dose": 2, "offset_days": 4200, "grace_days": 365, "description": "사람유두종바이러스 2차 (1차 후 6개월)"},

    # ── 매년 ──────────────────────────────────────
    {"name": "인플루엔자", "dose": 1, "offset_days": 180, "grace_days": 365, "description": "독감 (생후 6개월부터, 매년)"},
]


# (vaccine_name, dose) → grace_days. is_overdue 계산용 빠른 조회.
GRACE_DAYS_BY_VACCINE: dict[tuple[str, int], int] = {
    (entry["name"], entry["dose"]): entry["grace_days"] for entry in VACCINATION_SCHEDULE
}
DEFAULT_GRACE_DAYS = 30
