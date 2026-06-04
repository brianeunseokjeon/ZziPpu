from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.infrastructure.persistence.database import AsyncSessionFactory, engine
from app.infrastructure.persistence.models.base import Base
from app.infrastructure.persistence.models import (  # noqa: F401 — register models
    EmailOtpModel,
    TermModel,
    TermsAgreementModel,
    UserModel,
)
from app.infrastructure.persistence.repositories.terms_repository_impl import TermsRepositoryImpl
from app.infrastructure.terms.seed import seed_terms
from app.presentation.api.v1.router import v1_router
from app.presentation.middleware.error_handler import ErrorHandlerMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    # 약관 seed (마크다운 → terms upsert)
    async with AsyncSessionFactory() as session:
        await seed_terms(TermsRepositoryImpl(session))
        await session.commit()
    yield


app = FastAPI(title="먹놀잠 Auth Service", lifespan=lifespan)

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
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "auth"}
