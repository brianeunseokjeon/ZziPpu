import re
from uuid import UUID

from pydantic import BaseModel, EmailStr, field_validator


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ── OTP ────────────────────────────────────────────────────────────

_PHONE_RE = re.compile(r"^\+?[0-9\-\s]+$")


def _to_e164_kr(value: str) -> str:
    """01012345678 / 010-1234-5678 / +821012345678 → +821012345678."""
    if not value:
        raise ValueError("핸드폰 번호가 비어 있습니다.")
    if not _PHONE_RE.match(value):
        raise ValueError("핸드폰 번호 형식이 올바르지 않습니다.")
    digits = re.sub(r"[^0-9]", "", value)
    if value.strip().startswith("+"):
        return "+" + digits
    if digits.startswith("82"):
        return "+" + digits
    if digits.startswith("0"):
        return "+82" + digits[1:]
    raise ValueError("지원하지 않는 핸드폰 번호 형식입니다.")


class OtpRequestRequest(BaseModel):
    phone: str

    @field_validator("phone")
    @classmethod
    def normalize_phone(cls, v: str) -> str:
        return _to_e164_kr(v)


class OtpVerifyRequest(BaseModel):
    phone: str
    code: str

    @field_validator("phone")
    @classmethod
    def normalize_phone(cls, v: str) -> str:
        return _to_e164_kr(v)

    @field_validator("code")
    @classmethod
    def code_digits_only(cls, v: str) -> str:
        v = v.strip()
        if not v.isdigit() or len(v) != 6:
            raise ValueError("인증번호는 6자리 숫자여야 합니다.")
        return v


class OtpVerifyResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: UUID
    baby_id: UUID
    is_new_user: bool
