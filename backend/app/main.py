from contextlib import asynccontextmanager
from collections.abc import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.infrastructure.persistence.database import engine
from app.infrastructure.persistence.models.base import Base
from app.presentation.api.v1.router import v1_router
from app.presentation.middleware.error_handler import ErrorHandlerMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


app = FastAPI(
    title="먹놀잠 API",
    description="신생아 육아 기록 서비스 API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(ErrorHandlerMiddleware)

app.include_router(v1_router)


@app.get("/health")
async def health_check() -> dict:
    return {"status": "ok"}
