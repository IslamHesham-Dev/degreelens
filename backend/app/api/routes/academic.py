from __future__ import annotations

from collections.abc import Callable
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.concurrency import run_in_threadpool

from app.schemas.academic import (
    AdvisoryContextResponse,
    AdvisoryContextUpdate,
    CourseGradesResponse,
    CourseListResponse,
    GradeSeasonListResponse,
    TranscriptResponse,
    TranscriptWindowResponse,
    TranscriptYearListResponse,
)
from app.sessions.models import StudentSession
from app.dependencies import get_student_session

router = APIRouter(prefix="/academic", tags=["academic data"])


async def _portal_call(callable_: Callable[[], Any]) -> Any:
    try:
        return await run_in_threadpool(callable_)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from None
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="GIU portal is temporarily unavailable. Try again shortly.",
        ) from None


@router.get("/context", response_model=AdvisoryContextResponse)
def context(
    student: StudentSession = Depends(get_student_session),
) -> dict[str, Any]:
    return student.academic.context()


@router.post(
    "/context",
    response_model=AdvisoryContextResponse,
    include_in_schema=False,
)
@router.post(
    "/advisory-semester",
    response_model=AdvisoryContextResponse,
)
async def update_context(
    payload: AdvisoryContextUpdate,
    student: StudentSession = Depends(get_student_session),
) -> dict[str, Any]:
    def update() -> dict[str, Any]:
        with student.chat_lock:
            result = student.academic.select_current_season(
                payload.current_season
            )
            # The system prompt contains the selected semester, so rebuild the
            # agent and its transcript together to avoid stale context.
            student.conversation.clear()
            student.agent = None
            return result

    return await _portal_call(update)


@router.get("/seasons", response_model=GradeSeasonListResponse)
async def seasons(
    student: StudentSession = Depends(get_student_session),
) -> dict[str, Any]:
    values = await _portal_call(student.academic.list_grade_seasons)
    return {"seasons": values}


@router.get("/courses", response_model=CourseListResponse)
async def courses(
    season: str | None = Query(default=None, max_length=80),
    student: StudentSession = Depends(get_student_session),
) -> dict[str, Any]:
    return await _portal_call(lambda: student.academic.list_courses(season))


@router.get("/course-grades", response_model=CourseGradesResponse)
async def course_grades(
    course: str = Query(min_length=1, max_length=240),
    season: str | None = Query(default=None, max_length=80),
    student: StudentSession = Depends(get_student_session),
) -> dict[str, Any]:
    return await _portal_call(
        lambda: student.academic.course_grades(course, season)
    )


@router.get("/transcript-years", response_model=TranscriptYearListResponse)
async def transcript_years(
    student: StudentSession = Depends(get_student_session),
) -> dict[str, Any]:
    years = await _portal_call(student.academic.list_transcript_years)
    return {"years": years}


@router.get("/transcript", response_model=TranscriptResponse)
async def transcript(
    year: str | None = Query(default=None, max_length=80),
    student: StudentSession = Depends(get_student_session),
) -> dict[str, Any]:
    return await _portal_call(lambda: student.academic.transcript(year))


@router.get("/transcript-window", response_model=TranscriptWindowResponse)
async def transcript_window(
    student: StudentSession = Depends(get_student_session),
) -> dict[str, Any]:
    return await _portal_call(student.academic.full_transcript)


@router.post("/cache/clear")
def clear_cache(
    student: StudentSession = Depends(get_student_session),
) -> dict[str, str]:
    student.academic.clear_cache()
    return {"message": "Portal cache cleared."}
