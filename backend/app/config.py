from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    DATABASE_URL: str = "sqlite+aiosqlite:///./muknoljam.db"
    ANTHROPIC_API_KEY: str = ""
    # 고정 도메인은 정확 일치 목록으로, 동적 프리뷰 도메인(예: Vercel)은 정규식으로 허용.
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]
    CORS_ORIGIN_REGEX: str | None = None
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7
    DEV_MODE: bool = True

    # ── 내부 서비스 호출 (auth-service → core) ─────────────────────────
    # auth-service 와 동일한 값을 공유한다. 공동양육자 코드 리딤에 사용.
    INTERNAL_API_KEY: str = "change-me-internal-key"


settings = Settings()
