from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class AuthSettings(BaseSettings):
    """auth_svc 전용 설정. DATABASE_URL 충돌 방지를 위해 AUTH_DATABASE_URL 사용."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # --- DB (core의 DATABASE_URL 과 분리된 별도 env 키) ---
    AUTH_DATABASE_URL: str = "sqlite+aiosqlite:///./auth.db"

    # --- JWT (core-service 와 동일값이어야 함 — 같은 env 읽음) ---
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 365 * 100  # 100년 = 사실상 만료 없음(한 번 로그인 유지)

    # --- CORS (core main.py 에서 합집합으로 처리하므로 참조용) ---
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]
    CORS_ORIGIN_REGEX: str | None = None

    # --- OTP ---
    OTP_CODE_LENGTH: int = 6
    OTP_TTL_SECONDS: int = 300  # 5분
    OTP_MAX_ATTEMPTS: int = 5
    OTP_RESEND_COOLDOWN_SECONDS: int = 60
    OTP_MAX_PER_HOUR_PER_EMAIL: int = 5
    OTP_MAX_PER_HOUR_PER_IP: int = 20

    # --- Email provider (교체 가능) ---
    EMAIL_PROVIDER: str = "console"  # console | resend
    RESEND_API_KEY: str = ""
    EMAIL_FROM: str = "먹놀잠 <onboarding@resend.dev>"

    # --- core-service 내부 호출 (통합 후 자기 자신 URL) ---
    CORE_URL: str = "http://localhost:8080"
    INTERNAL_API_KEY: str = "change-me-internal-key"

    # --- 휴대폰 OTP (비활성 보존) ---
    PHONE_OTP_ENABLED: bool = False

    # --- dev ---
    DEV_MODE: bool = True


@lru_cache
def get_auth_settings() -> AuthSettings:
    return AuthSettings()


settings = get_auth_settings()
