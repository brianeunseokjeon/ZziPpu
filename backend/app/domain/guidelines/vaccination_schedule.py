from typing import TypedDict


class VaccineEntry(TypedDict):
    name: str
    dose: int
    offset_days: int
    description: str


# 대한소아청소년과학회 표준 예방접종 일정 (생후 일수 기준)
VACCINATION_SCHEDULE: list[VaccineEntry] = [
    {"name": "BCG", "dose": 1, "offset_days": 0, "description": "결핵"},
    {"name": "B형간염", "dose": 1, "offset_days": 0, "description": "B형 간염"},
    {"name": "B형간염", "dose": 2, "offset_days": 30, "description": "B형 간염"},
    {"name": "B형간염", "dose": 3, "offset_days": 180, "description": "B형 간염"},
    {"name": "DTaP", "dose": 1, "offset_days": 60, "description": "디프테리아/파상풍/백일해"},
    {"name": "DTaP", "dose": 2, "offset_days": 120, "description": "디프테리아/파상풍/백일해"},
    {"name": "DTaP", "dose": 3, "offset_days": 180, "description": "디프테리아/파상풍/백일해"},
    {"name": "DTaP", "dose": 4, "offset_days": 540, "description": "디프테리아/파상풍/백일해"},
    {"name": "IPV", "dose": 1, "offset_days": 60, "description": "폴리오"},
    {"name": "IPV", "dose": 2, "offset_days": 120, "description": "폴리오"},
    {"name": "IPV", "dose": 3, "offset_days": 180, "description": "폴리오"},
    {"name": "IPV", "dose": 4, "offset_days": 540, "description": "폴리오"},
    {"name": "Hib", "dose": 1, "offset_days": 60, "description": "뇌수막염"},
    {"name": "Hib", "dose": 2, "offset_days": 120, "description": "뇌수막염"},
    {"name": "Hib", "dose": 3, "offset_days": 180, "description": "뇌수막염"},
    {"name": "Hib", "dose": 4, "offset_days": 365, "description": "뇌수막염"},
    {"name": "PCV", "dose": 1, "offset_days": 60, "description": "폐렴구균"},
    {"name": "PCV", "dose": 2, "offset_days": 120, "description": "폐렴구균"},
    {"name": "PCV", "dose": 3, "offset_days": 180, "description": "폐렴구균"},
    {"name": "PCV", "dose": 4, "offset_days": 365, "description": "폐렴구균"},
    {"name": "로타바이러스", "dose": 1, "offset_days": 60, "description": "장염"},
    {"name": "로타바이러스", "dose": 2, "offset_days": 120, "description": "장염"},
    {"name": "로타바이러스", "dose": 3, "offset_days": 180, "description": "장염"},
    {"name": "MMR", "dose": 1, "offset_days": 365, "description": "홍역/유행성이하선염/풍진"},
    {"name": "수두", "dose": 1, "offset_days": 365, "description": "수두"},
    {"name": "A형간염", "dose": 1, "offset_days": 365, "description": "A형 간염"},
    {"name": "A형간염", "dose": 2, "offset_days": 548, "description": "A형 간염"},
    {"name": "일본뇌염", "dose": 1, "offset_days": 730, "description": "일본뇌염"},
    {"name": "일본뇌염", "dose": 2, "offset_days": 744, "description": "일본뇌염"},
]
