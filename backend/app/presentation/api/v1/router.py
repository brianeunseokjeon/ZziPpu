from fastapi import APIRouter

from app.presentation.api.v1.auth_router import router as auth_router
from app.presentation.api.v1.baby_router import router as baby_router
from app.presentation.api.v1.feeding_router import router as feeding_router
from app.presentation.api.v1.diaper_router import router as diaper_router
from app.presentation.api.v1.sleep_router import router as sleep_router
from app.presentation.api.v1.play_router import router as play_router
from app.presentation.api.v1.dashboard_router import router as dashboard_router
from app.presentation.api.v1.ai_router import router as ai_router

v1_router = APIRouter(prefix="/api/v1")

v1_router.include_router(auth_router)
v1_router.include_router(baby_router)
v1_router.include_router(feeding_router)
v1_router.include_router(diaper_router)
v1_router.include_router(sleep_router)
v1_router.include_router(play_router)
v1_router.include_router(dashboard_router)
v1_router.include_router(ai_router)
