from enum import Enum


class DiaperType(str, Enum):
    PEE = "pee"
    POO = "poo"
    BOTH = "both"
