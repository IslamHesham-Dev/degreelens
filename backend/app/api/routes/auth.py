from __future__ import annotations

import requests
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.concurrency import run_in_threadpool

from guc_portal import GucPortal

from app.config import get_settings
from app.dependencies import get_access_token, get_student_session
from app.schemas.auth import (
    LoginRequest,
    LoginResponse,
    MessageResponse,
    SessionResponse,
)
from app.sessions.models import StudentSession
from app.state import session_store

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/login", response_model=LoginResponse)
async def login(payload: LoginRequest) -> LoginResponse:
    settings = get_settings()
    portal = GucPortal(
        username=payload.username.strip(),
        password=payload.password.get_secret_value(),
        site="giu",
    )
    try:
        await run_in_threadpool(
            lambda: portal.available_seasons(tries=1, delay=0)
        )
    except requests.HTTPError as exc:
        portal.session.auth = None
        portal.session.close()
        response = exc.response
        if response is not None and response.status_code in {401, 403}:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="GIU rejected the username or password.",
            ) from None
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="GIU portal is temporarily unavailable. Try again shortly.",
        ) from None
    except Exception:
        portal.session.auth = None
        portal.session.close()
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not establish a GIU portal session.",
        ) from None

    token, student = session_store.create(portal)
    return LoginResponse(
        access_token=token,
        expires_in_seconds=student.expires_in_seconds,
        current_season=settings.current_season,
        advisory_year=settings.advisory_year,
    )


@router.get("/session", response_model=SessionResponse)
def session_status(
    student: StudentSession = Depends(get_student_session),
) -> SessionResponse:
    return SessionResponse(
        authenticated=True,
        expires_in_seconds=student.expires_in_seconds,
        current_season=student.academic.current_season,
        advisory_year=student.academic.advisory_year,
    )


@router.post("/logout", response_model=MessageResponse)
def logout(token: str = Depends(get_access_token)) -> MessageResponse:
    session_store.delete(token)
    return MessageResponse(message="Signed out securely.")
