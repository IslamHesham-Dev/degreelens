from app.academic import AcademicService
from app.main import app
from guc_portal.models import Transcript, TranscriptRow


class FakePortal:
    def available_seasons(
        self, *, tries: int, delay: float
    ) -> list[tuple[str, str]]:
        return [
            ("spring-2027", "Spring 2027"),
            ("spring-2025", "Spring 2025"),
            ("winter-2024", "Winter 2024"),
            ("spring-2024", "Spring 2024"),
        ]

    def list_previous_courses(
        self, season_value: str, *, tries: int, delay: float
    ) -> list[tuple[str, str]]:
        return [(f"{season_value}-course", f"{season_value} course")]

    def available_years(
        self, *, tries: int, delay: float
    ) -> list[tuple[str, str]]:
        return [
            ("2020", "2020-2021"),
            ("2021", "2021-2022"),
            ("2022", "2022-2023"),
            ("2023", "2023-2024"),
            ("2024", "2024-2025"),
            ("2025", "2025-2026"),
        ]

    def get_transcript_year(
        self, year_value: str, *, tries: int, delay: float
    ) -> Transcript:
        semesters = {
            "2021": "Winter 2021",
            "2022": "Spring 2022",
            "2023": "Winter 2023",
            "2024": "Spring 2025",
        }
        semester = semesters.get(year_value)
        rows = (
            [
                TranscriptRow(
                    semester=semester,
                    course=f"Course {year_value}",
                    grade="A",
                    numeric="1.2",
                    hours="4",
                    group="Core",
                )
            ]
            if semester
            else []
        )
        return Transcript(rows=rows, cumulative_gpa="1.45" if rows else None)


def test_select_current_season_changes_default_course_context() -> None:
    academic = AcademicService(
        FakePortal(),  # type: ignore[arg-type]
        current_season="Winter 2024",
        advisory_year="2024-2025",
    )

    context = academic.select_current_season("Spring 2024")
    courses = academic.list_courses()

    assert context["simulated_current_season"] == "Spring 2024"
    assert courses["season"] == "Spring 2024"


def test_select_current_season_accepts_unique_fragment() -> None:
    academic = AcademicService(
        FakePortal(),  # type: ignore[arg-type]
        current_season="Winter 2024",
        advisory_year="2024-2025",
    )

    context = academic.select_current_season("Winter")

    assert context["simulated_current_season"] == "Winter 2024"


def test_advisory_semester_update_has_an_explicit_post_route() -> None:
    operation = app.openapi()["paths"]["/v1/academic/advisory-semester"]

    assert "post" in operation


def test_enrollment_year_limits_transcript_to_four_academic_years() -> None:
    academic = AcademicService(
        FakePortal(),  # type: ignore[arg-type]
        current_season="Winter 2024",
        advisory_year="2024-2025",
        enrollment_year=2021,
    )

    transcript = academic.full_transcript()

    assert transcript["requested_years"] == [
        "2021-2022",
        "2022-2023",
        "2023-2024",
        "2024-2025",
    ]
    assert transcript["loaded_years"] == transcript["requested_years"]
    assert {row["academic_year"] for row in transcript["courses"]} == set(
        transcript["requested_years"]
    )
    assert academic.list_transcript_years() == transcript["requested_years"]


def test_latest_real_transcript_semester_is_auto_selected() -> None:
    academic = AcademicService(
        FakePortal(),  # type: ignore[arg-type]
        current_season="Spring 2027",
        advisory_year="2025-2026",
        enrollment_year=2021,
    )

    context = academic.select_latest_actual_context()

    assert context["transcript_year"] == "2024-2025"
    assert context["simulated_current_season"] == "Spring 2025"
