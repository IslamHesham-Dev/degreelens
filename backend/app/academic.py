from __future__ import annotations

import threading
from typing import Any

from guc_portal import GucPortal


class AcademicService:
    """Per-student, read-only access to portal data with an isolated cache."""

    def __init__(
        self,
        portal: GucPortal,
        *,
        current_season: str,
        advisory_year: str,
    ) -> None:
        self.portal = portal
        self.current_season = current_season
        self.advisory_year = advisory_year
        self.cache: dict[Any, Any] = {}
        self.portal_lock = threading.RLock()

    @staticmethod
    def _pick(
        options: list[tuple[str, str]], query: str, kind: str
    ) -> tuple[str, str]:
        needle = query.strip().casefold()
        exact = [
            (value, label)
            for value, label in options
            if label.casefold() == needle
        ]
        matches = exact or [
            (value, label)
            for value, label in options
            if needle in label.casefold()
        ]
        if not matches:
            raise ValueError(f"No {kind} matches {query!r}.")
        if len(matches) > 1:
            labels = [label for _value, label in matches]
            raise ValueError(f"Ambiguous {kind} {query!r}; matches: {labels}")
        return matches[0]

    def _seasons(self) -> list[tuple[str, str]]:
        with self.portal_lock:
            if "seasons" not in self.cache:
                self.cache["seasons"] = self.portal.available_seasons(
                    tries=2, delay=60
                )
            return self.cache["seasons"]

    def _courses(self, season_value: str) -> list[tuple[str, str]]:
        key = ("courses", season_value)
        with self.portal_lock:
            if key not in self.cache:
                self.cache[key] = self.portal.list_previous_courses(
                    season_value, tries=2, delay=60
                )
            return self.cache[key]

    def _years(self) -> list[tuple[str, str]]:
        with self.portal_lock:
            if "years" not in self.cache:
                self.cache["years"] = self.portal.available_years(
                    tries=2, delay=60
                )
            return self.cache["years"]

    def context(self) -> dict[str, Any]:
        return {
            "simulated_current_season": self.current_season,
            "transcript_year": self.advisory_year,
            "data_sources": [
                "GIU portal detailed grades",
                "GIU transcript",
            ],
            "excluded_sources": ["CMS", "live current-course page"],
        }

    def list_grade_seasons(self) -> list[str]:
        return [label for _value, label in self._seasons()]

    def select_current_season(self, season: str) -> dict[str, Any]:
        """Validate and select the season used by advisory tools."""
        _value, season_label = self._pick(
            self._seasons(), season, "season"
        )
        self.current_season = season_label
        return self.context()

    def list_courses(self, season: str | None = None) -> dict[str, Any]:
        requested = season or self.current_season
        season_value, season_label = self._pick(
            self._seasons(), requested, "season"
        )
        return {
            "season": season_label,
            "courses": [
                label for _value, label in self._courses(season_value)
            ],
        }

    def course_grades(
        self, course: str, season: str | None = None
    ) -> dict[str, Any]:
        requested = season or self.current_season
        season_value, season_label = self._pick(
            self._seasons(), requested, "season"
        )
        course_value, course_label = self._pick(
            self._courses(season_value), course, "course"
        )
        key = ("grades", season_value, course_value)
        with self.portal_lock:
            if key not in self.cache:
                grades = self.portal.get_previous_grades(
                    season_value,
                    course_value,
                    tries=2,
                    delay=60,
                )
                self.cache[key] = {
                    "season": season_label,
                    "course": course_label,
                    "assessments": [
                        {
                            "assessment": item.assessment,
                            "element": item.element,
                            "grade": item.grade,
                            "evaluator": item.evaluator,
                        }
                        for item in grades.items
                    ],
                    "midterm_results": grades.percentages,
                }
            return self.cache[key]

    def list_transcript_years(self) -> list[str]:
        return [label for _value, label in self._years()]

    def transcript(self, year: str | None = None) -> dict[str, Any]:
        requested = year or self.advisory_year
        year_value, year_label = self._pick(
            self._years(), requested, "transcript year"
        )
        key = ("transcript", year_value)
        with self.portal_lock:
            if key not in self.cache:
                transcript = self.portal.get_transcript_year(
                    year_value, tries=2, delay=60
                )
                self.cache[key] = {
                    "year": year_label,
                    "cumulative_gpa": transcript.cumulative_gpa,
                    "courses": [
                        {
                            "semester": row.semester,
                            "course": row.course,
                            "grade": row.grade,
                            "numeric": row.numeric,
                            "hours": row.hours,
                            "group": row.group,
                        }
                        for row in transcript.rows
                    ],
                }
            return self.cache[key]

    def find_transcript_course(
        self, course: str, year: str | None = None
    ) -> dict[str, Any]:
        data = self.transcript(year)
        needle = course.strip().casefold()
        return {
            "year": data["year"],
            "query": course,
            "matches": [
                row
                for row in data["courses"]
                if needle in row["course"].casefold()
            ],
        }

    def clear_cache(self) -> None:
        with self.portal_lock:
            self.cache.clear()
