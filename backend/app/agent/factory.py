from __future__ import annotations

import json
from typing import Any

from langchain.agents import create_agent
from langchain.tools import tool
from langchain_anthropic import ChatAnthropic

from app.config import Settings
from app.sessions.models import StudentSession


def _safe(callable_) -> dict[str, Any] | list[str]:
    try:
        return callable_()
    except ValueError as exc:
        return {"error": str(exc)}
    except Exception:
        return {
            "error": "The GIU portal is temporarily unavailable.",
            "advice": "Wait about one minute, then try again.",
        }


def build_agent(student: StudentSession, settings: Settings):
    academic = student.academic

    @tool
    def get_advisory_context() -> dict:
        """Return the simulated current semester, transcript year, and data limits."""
        return academic.context()

    @tool
    def list_advisory_courses() -> dict:
        """List courses in the configured simulated current semester."""
        return _safe(academic.list_courses)

    @tool
    def get_advisory_course_grades(course: str) -> dict:
        """Get detailed grades for a current-advisory-semester course.
        The course may be an exact GIU label or a unique fragment such as ICS501."""
        return _safe(lambda: academic.course_grades(course))

    @tool
    def get_advisory_transcript() -> dict:
        """Get the transcript for the configured advisory academic year."""
        return _safe(academic.transcript)

    @tool
    def list_grade_seasons() -> list[str] | dict:
        """List all GIU seasons that expose detailed grades."""
        return _safe(academic.list_grade_seasons)

    @tool
    def list_courses_in_season(season: str) -> dict:
        """List exact GIU course labels inside a named historical season."""
        return _safe(lambda: academic.list_courses(season))

    @tool
    def get_course_grades(season: str, course: str) -> dict:
        """Get detailed assessment grades for one course in a historical season."""
        return _safe(lambda: academic.course_grades(course, season))

    @tool
    def get_transcript(year: str) -> dict:
        """Get transcript courses, grades, credits, and GPA for an academic year."""
        return _safe(lambda: academic.transcript(year))

    @tool
    def find_transcript_course(year: str, course: str) -> dict:
        """Find course rows in one transcript year by a name or code fragment."""
        return _safe(lambda: academic.find_transcript_course(course, year))

    api_key = settings.anthropic_api_key.get_secret_value()
    if not api_key:
        raise RuntimeError("ANTHROPIC_API_KEY is not configured on the backend.")

    model = ChatAnthropic(
        model=settings.anthropic_model,
        temperature=0,
        api_key=api_key,
    )
    tools = [
        get_advisory_context,
        list_advisory_courses,
        get_advisory_course_grades,
        get_advisory_transcript,
        list_grade_seasons,
        list_courses_in_season,
        get_course_grades,
        get_transcript,
        find_transcript_course,
    ]
    prompt = (
        "You are DegreeLens, a read-only academic advisor and study-planning "
        "assistant for a GIU student. Use portal tools for every factual claim "
        "about the student's records. "
        f"Treat {settings.current_season} as the simulated current semester and "
        f"{settings.advisory_year} as its advisory transcript year. When the "
        "student says current semester or my courses, use the advisory tools. "
        "For detailed grades, identify a season, resolve the course, then fetch "
        "its assessment rows. Clearly distinguish earned marks from maximum marks. "
        "Summarize strengths, weak assessments, and practical study priorities. "
        "CMS is unavailable and out of scope. You do not know course content, "
        "deadlines, attendance, prerequisites, schedules, or graduation rules "
        "unless the student supplies them. Separate portal facts from recommendations "
        "and never present advice as official university policy. The portal is slow, "
        "so make the fewest calls possible and reuse existing results. Do not fetch "
        "every course's details unless explicitly requested. Never invent records."
    )
    return create_agent(model=model, tools=tools, system_prompt=prompt)


def message_text(content: Any) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = [
            block.get("text", "")
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        ]
        return "\n".join(part for part in parts if part)
    return str(content)


def tool_events(messages: list[Any]) -> tuple[list[dict[str, str]], list[str]]:
    events: list[dict[str, str]] = []
    sources: list[str] = []
    source_map = {
        "get_advisory_context": "Advisory context",
        "list_advisory_courses": "GIU detailed-grade seasons",
        "get_advisory_course_grades": "GIU detailed grades",
        "get_advisory_transcript": "GIU transcript",
        "list_grade_seasons": "GIU detailed-grade seasons",
        "list_courses_in_season": "GIU detailed-grade seasons",
        "get_course_grades": "GIU detailed grades",
        "get_transcript": "GIU transcript",
        "find_transcript_course": "GIU transcript",
    }
    for message in messages:
        if getattr(message, "type", "") != "tool":
            continue
        name = getattr(message, "name", None) or "portal_tool"
        status = "completed"
        content = getattr(message, "content", "")
        if isinstance(content, str):
            try:
                parsed = json.loads(content)
            except (TypeError, json.JSONDecodeError):
                parsed = None
            if isinstance(parsed, dict) and "error" in parsed:
                status = "error"
        events.append({"name": name, "status": status})
        source = source_map.get(name)
        if source and source not in sources:
            sources.append(source)
    return events, sources
