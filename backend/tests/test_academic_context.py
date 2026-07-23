from app.academic import AcademicService


class FakePortal:
    def available_seasons(
        self, *, tries: int, delay: float
    ) -> list[tuple[str, str]]:
        return [
            ("winter-2024", "Winter 2024"),
            ("spring-2024", "Spring 2024"),
        ]

    def list_previous_courses(
        self, season_value: str, *, tries: int, delay: float
    ) -> list[tuple[str, str]]:
        return [(f"{season_value}-course", f"{season_value} course")]


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

    context = academic.select_current_season("Spring")

    assert context["simulated_current_season"] == "Spring 2024"
