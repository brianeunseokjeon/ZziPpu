from fastapi import APIRouter

from app.presentation.api.v1.auth_router import router as auth_router
from app.presentation.api.v1.code_router import router as code_router
from app.presentation.api.v1.terms_router import router as terms_router

v1_router = APIRouter(prefix="/api/v1")

v1_router.include_router(auth_router)
v1_router.include_router(code_router)
v1_router.include_router(terms_router)
