"""Plain data holders for the student portal (grades, transcript)."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class TranscriptRow:
    """One course on the transcript."""

    semester: str  # e.g. "Winter 2024", "Spring 2025"
    course: str  # e.g. "Operating Systems"
    grade: str  # letter grade, e.g. "A+"
    numeric: str  # GUC numeric grade, e.g. "0.7" (lower is better)
    hours: str  # credit hours, e.g. "4"
    group: str  # the study-group code shown next to it, e.g. "CSE06"


@dataclass
class Transcript:
    """The whole transcript: every course, plus the cumulative GPA."""

    rows: list[TranscriptRow]
    cumulative_gpa: str | None

    def by_semester(self) -> dict[str, list[TranscriptRow]]:
        """Group the rows by their semester, in the order they appear."""
        out: dict[str, list[TranscriptRow]] = {}
        for row in self.rows:
            out.setdefault(row.semester, []).append(row)
        return out


@dataclass
class GradeItem:
    """One graded element of a course: a quiz question, an assignment, an exam."""

    assessment: str  # e.g. "HW01", "Quiz 1", "Midterm"
    element: str  # e.g. "Question1"
    grade: str  # e.g. "3 / 3" (earned / max)
    evaluator: str  # who graded it, e.g. "Ahmed Abd Elreheem Tawfik"


@dataclass
class CourseGrades:
    """The coursework marks for one course in one semester.

    `items` is the detailed breakdown. `percentages` is the small summary the
    page shows for every course in that semester (course name -> percentage), so
    you also get the overall standing in one shot.
    """

    course: str  # the course we asked about
    season: str | None  # e.g. "Winter 2024", or None for the current term
    items: list[GradeItem]
    percentages: dict[str, str]
