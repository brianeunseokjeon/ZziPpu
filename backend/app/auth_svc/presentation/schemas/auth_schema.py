from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class EmailOtpRequestRequest(BaseModel):
    email: EmailStr


class EmailOtpVerifyRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=4, max_length=8)


class EmailOtpVerifyResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: UUID
    is_new_user: bool
    terms_required: bool


class CodeRedeemRequest(BaseModel):
    code: str = Field(min_length=4, max_length=32)


class CodeRedeemResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: UUID
    baby_id: UUID
    is_new_user: bool = True
    terms_required: bool
