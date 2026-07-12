from enum import Enum


class DiaperAmount(str, Enum):
    LITTLE = "little"
    NORMAL = "normal"
    LOT = "lot"
