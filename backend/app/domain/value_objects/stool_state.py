from enum import Enum


class StoolState(str, Enum):
    WATERY = "watery"
    SOFT = "soft"
    NORMAL = "normal"
    HARD = "hard"
