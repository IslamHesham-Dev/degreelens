"""Turn portal HTML into dataclasses. HTML in, data out, no network here."""

from __future__ import annotations

import re

from bs4 import BeautifulSoup

from .models import CourseGrades, GradeItem, Transcript, TranscriptRow

# The transcript header row we look for to know a table holds courses.
_TRANSCRIPT_HEADER = {"course name", "grade", "numeric", "hours"}


def _cells(row) -> list[str]:
    """Text from cells that belong directly to `row`, excluding nested tables."""
    return [
        cell.get_text(" ", strip=True)
        for cell in row.find_all(["th", "td"], recursive=False)
    ]


def _table_rows(table) -> list:
    """Rows owned by `table`, excluding rows from tables nested inside it."""
    return [
        row
        for row in table.find_all("tr")
        if row.find_parent("table") is table
    ]


def parse_transcript_year(html: str) -> tuple[list[TranscriptRow], str | None]:
    """Parse ONE study-year page: its course rows and (if shown) the GPA.

    Each semester is its own little table: the first row is the semester name
    ("Winter 2024"), the next row is the column header, then one row per course.
    Some tables are just a GPA placeholder with no courses; we skip those.
    """
    soup = BeautifulSoup(html, "lxml")
    rows: list[TranscriptRow] = []

    for table in soup.find_all("table"):
        trs = _table_rows(table)
        if len(trs) < 3:
            continue
        semester = _cells(trs[0])[0] if _cells(trs[0]) else ""
        header = [h.lower() for h in _cells(trs[1])]
        if "course name" not in header:
            continue
        for tr in trs[2:]:
            c = _cells(tr)
            if len(c) < 5:
                continue
            group, course, numeric, grade, hours = c[0], c[1], c[2], c[3], c[4]
            if not course or "semester gpa" in course.lower():
                continue
            rows.append(
                TranscriptRow(
                    semester=semester,
                    course=course,
                    grade=grade,
                    numeric=re.sub(r"\s+", "", numeric),
                    hours=re.sub(r"\s+", "", hours),
                    group=group,
                )
            )

    gpa_el = soup.find("span", id=re.compile("cmGpaLbl", re.I))
    gpa = gpa_el.get_text(strip=True) if gpa_el else None
    return rows, gpa


def parse_options(html: str, select_id: str) -> list[tuple[str, str]]:
    """Read a dropdown's options as [(value, label), ...], skipping placeholders.

    Placeholders are the "Choose a ..." entries whose value is empty or blank.
    """
    soup = BeautifulSoup(html, "lxml")
    select = soup.find("select", id=re.compile(select_id))
    if not select:
        return []
    out = []
    for opt in select.find_all("option"):
        value = opt.get("value")
        if value and value.strip():
            out.append((value, opt.get_text(strip=True)))
    return out


def parse_course_grades(html: str, course: str, season: str | None) -> CourseGrades:
    """Read a coursework-grades page: the per-element marks and the % summary.

    Two tables live on the page:
      * the detailed one, with columns Quiz/Assignment, Element Name, Grade,
        and the grader's name;
      * a small one listing every course in the term with its percentage.
    """
    soup = BeautifulSoup(html, "lxml")
    items: list[GradeItem] = []
    seen_items: set[tuple[str, str, str, str]] = set()
    percentages: dict[str, str] = {}

    for table in soup.find_all("table"):
        trs = _table_rows(table)
        if len(trs) < 2:
            continue
        header = [h.lower() for h in _cells(trs[0])]

        if "quiz/assignment" in header or "element name" in header:
            for tr in trs[1:]:
                c = _cells(tr)
                if len(c) < 4:
                    continue
                assessment, element, grade, evaluator = c[0], c[1], c[2], c[3]
                grade = re.sub(r"\s*/\s*", " / ", re.sub(r"\s+", " ", grade)).strip()
                item_key = (assessment, element, grade, evaluator)
                is_header = (
                    assessment.casefold() == "quiz/assignment"
                    and element.casefold() == "element name"
                )
                if (assessment or element) and not is_header and item_key not in seen_items:
                    seen_items.add(item_key)
                    items.append(
                        GradeItem(
                            assessment=assessment,
                            element=element,
                            grade=grade,
                            evaluator=evaluator,
                        )
                    )

        elif "percentage" in header and "course" in header:
            for tr in trs[1:]:
                c = _cells(tr)
                if len(c) >= 2 and c[0]:
                    percentages[c[0]] = c[1]

    return CourseGrades(course=course, season=season, items=items, percentages=percentages)


def merge_transcript(
    per_year: list[tuple[list[TranscriptRow], str | None]],
) -> Transcript:
    """Combine the per-year results into one transcript, dropping duplicates."""
    seen: set[tuple[str, str]] = set()
    rows: list[TranscriptRow] = []
    gpa: str | None = None
    for year_rows, year_gpa in per_year:
        gpa = year_gpa or gpa
        for row in year_rows:
            key = (row.semester, row.course)
            if key in seen:
                continue
            seen.add(key)
            rows.append(row)
    return Transcript(rows=rows, cumulative_gpa=gpa)
