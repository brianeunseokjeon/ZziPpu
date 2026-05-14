from enum import Enum


class FeedingType(str, Enum):
    FORMULA = "formula"
    BREAST_LEFT = "breast_left"
    BREAST_RIGHT = "breast_right"
    BREAST_BOTH = "breast_both"
