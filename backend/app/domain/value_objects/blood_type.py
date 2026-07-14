from enum import Enum


class BloodType(str, Enum):
    A = "A"
    B = "B"
    O = "O"  # noqa: E741 — 혈액형 O형(도메인 상수, 모호 변수 아님)
    AB = "AB"
