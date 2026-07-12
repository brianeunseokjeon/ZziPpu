from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class CreateGrowthRequest(BaseModel):
    id: UUID | None = None  # 클라 생성 UUID(멱등 upsert). 생략 시 서버 생성(하위호환).
    recorded_at: date
    weight_g: int | None = Field(None, gt=0, description="체중 (그램)")
    height_cm: float | None = Field(None, gt=0, description="키 (cm)")
    head_circumference_cm: float | None = Field(None, gt=0, description="머리둘레 (cm)")
    memo: str | None = None


class UpdateGrowthRequest(BaseModel):
    # iOS는 편집 시 레코드 전체를 보냄(전체 교체). 모든 필드 옵셔널.
    recorded_at: date | None = None
    weight_g: int | None = Field(None, gt=0, description="체중 (그램)")
    height_cm: float | None = Field(None, gt=0, description="키 (cm)")
    head_circumference_cm: float | None = Field(None, gt=0, description="머리둘레 (cm)")
    memo: str | None = None


class GrowthResponse(BaseModel):
    id: UUID
    baby_id: UUID
    recorded_at: date
    weight_g: int | None
    height_cm: float | None
    head_circumference_cm: float | None
    memo: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
