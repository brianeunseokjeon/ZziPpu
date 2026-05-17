from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    DATABASE_URL: str = "sqlite+aiosqlite:///./muknoljam.db"
    ANTHROPIC_API_KEY: str = ""
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7
    DEV_MODE: bool = True

    # ── OTP / 핸드폰 인증 ───────────────────────────────────────────
    OTP_TTL_SECONDS: int = 300        # 5분
    OTP_LENGTH: int = 6
    OTP_MAX_ATTEMPTS: int = 5
    OTP_COOLDOWN_SECONDS: int = 60    # 같은 phone 재요청 cool-down
    OTP_HOURLY_PER_PHONE: int = 5
    OTP_HOURLY_PER_IP: int = 20

    # ── SMS Provider ──────────────────────────────────────────────
    # "console" : 백엔드 로그에만 출력 (개발용)
    # "ncp_sens": Naver Cloud Sens SMS
    SMS_PROVIDER: str = "console"
    SMS_API_KEY: str | None = None
    SMS_API_SECRET: str | None = None
    SMS_SERVICE_ID: str | None = None      # NCP Sens service id
    SMS_SENDER: str | None = None          # 발신번호 (예: "021234-5678")


settings = Settings()
