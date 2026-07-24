from __future__ import annotations

from pydantic import BaseModel, Field


class AdvisoryContextResponse(BaseModel):
    simulated_current_season: str
    transcript_year: str
    enrollment_year: int
    transcript_years: list[str]
    data_sources: list[str]
    excluded_sources: list[str]


class AdvisoryContextUpdate(BaseModel):
    current_season: str = Field(min_length=1, max_length=80)


class CourseListResponse(BaseModel):
    season: str
    courses: list[str]


class AssessmentResponse(BaseModel):
    assessment: str
    element: str
    grade: str
    evaluator: str


class CourseGradesResponse(BaseModel):
    season: str
    course: str
    assessments: list[AssessmentResponse]
    midterm_results: dict[str, str]


class TranscriptCourseResponse(BaseModel):
    semester: str
    course: str
    grade: str
    numeric: str
    hours: str
    group: str


class TranscriptResponse(BaseModel):
    year: str
    cumulative_gpa: str | None
    courses: list[TranscriptCourseResponse]


class TranscriptWindowCourseResponse(TranscriptCourseResponse):
    academic_year: str


class GradeSeasonListResponse(BaseModel):
    seasons: list[str]


class TranscriptYearListResponse(BaseModel):
    years: list[str]


class TranscriptWindowResponse(BaseModel):
    enrollment_year: int
    requested_years: list[str]
    loaded_years: list[str]
    cumulative_gpa: str | None
    courses: list[TranscriptWindowCourseResponse]


class CourseQuery(BaseModel):
    course: str = Field(min_length=1, max_length=240)
