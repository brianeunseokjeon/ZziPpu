from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # --- DB ---
    DATABASE_URL: str = "sqlite+aiosqlite:///./auth.db"

    # --- JWT (core-service 와 동일값이어야 함) ---
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7일

    # --- CORS ---
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]

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

    # --- core-service 내부 호출 ---
    CORE_URL: str = "http://localhost:8081"
    INTERNAL_API_KEY: str = "change-me-internal-key"

    # --- 휴대폰 OTP (비활성 보존) ---
    PHONE_OTP_ENABLED: bool = False

    # --- dev ---
    DEV_MODE: bool = True


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
