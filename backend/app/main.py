from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import academic, auth, chat, health
from app.config import get_settings
from app.state import session_store


@asynccontextmanager
async def lifespan(_app: FastAPI):
    yield
    session_store.close_all()


settings = get_settings()
app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description=(
        "Private, read-only GIU academic advisory API. "
        "The CMS connector is not configured yet."
    ),
    docs_url="/docs" if settings.environment != "production" else None,
    redoc_url=None,
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)
app.include_router(health.router)
app.include_router(auth.router, prefix="/v1")
app.include_router(academic.router, prefix="/v1")
app.include_router(chat.router, prefix="/v1")
