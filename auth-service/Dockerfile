FROM python:3.11-slim

WORKDIR /app

COPY pyproject.toml ./
RUN pip install --no-cache-dir \
    "fastapi>=0.115" "uvicorn[standard]>=0.30" "sqlalchemy>=2.0" "aiosqlite>=0.20" \
    "asyncpg>=0.29" "pydantic[email]>=2.7" "pydantic-settings>=2.3" \
    "python-jose[cryptography]>=3.3" "httpx>=0.27"

COPY app ./app

EXPOSE 8082

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8082"]
