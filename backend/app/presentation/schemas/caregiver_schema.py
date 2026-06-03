from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class InviteResponse(BaseModel):
    code: str
    expires_at: datetime


class JoinRequest(BaseModel):
    code: str = Field(min_length=4, max_length=12)


class CaregiverMemberResponse(BaseModel):
    user_id: UUID
    role: str
    created_at: datetime
