FROM python:3.11-slim

WORKDIR /app

COPY pyproject.toml ./
# 통합 앱 의존성: core + auth-service 합집합
# auth-service 추가: pydantic[email](이미 pydantic-settings로 커버), httpx(이미 있음)
# resend 이메일 발송은 httpx 기반 직접 구현이므로 별도 SDK 불필요
RUN pip install --no-cache-dir \
    "fastapi>=0.115" "uvicorn[standard]>=0.30" "sqlalchemy>=2.0" "aiosqlite>=0.20" \
    "asyncpg>=0.29" "alembic>=1.13" "pydantic[email]>=2.7" "pydantic-settings>=2.3" \
    "anthropic>=0.39" "python-jose[cryptography]>=3.3" "passlib[bcrypt]>=1.7" \
    "httpx>=0.27" "sse-starlette>=2.1" "youtube-transcript-api>=0.6"

COPY app ./app

EXPOSE 8080

# Render는 $PORT를 주입한다. 로컬/compose에선 미설정 시 8080 사용.
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}
