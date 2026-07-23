"""Which university portal are we talking to?

GUC (Cairo) and GIU run the same SIS/portal software, so one client works for
both. Only the host and a few page paths differ, and they live here. Pick a site
with `GucPortal(site="guc")` or the GUC_SITE env var.

The transcript-year and course dropdown suffixes are shared, but the season
suffix differs: GUC uses `Dropdownlistseason`, GIU uses `ddl_season`. Each site
profile stores that difference. Full postback field names are still discovered
from the live page instead of hard-coded.

GUC is verified against the live portal. GIU's transcript and previous-grades
flows are also verified, including season and course postbacks.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PortalSite:
    base_url: str
    transcript_path: str
    prev_grades_path: str
    curr_grades_path: str
    season_suffix: str


PORTAL_SITES: dict[str, PortalSite] = {
    "guc": PortalSite(
        base_url="https://apps.guc.edu.eg",
        transcript_path="/student_ext/Grade/Transcript_001.aspx",
        prev_grades_path="/student_ext/Grade/CheckGradePerviousSemester_01.aspx",
        curr_grades_path="/student_ext/Grade/CheckGrade_01.aspx",
        season_suffix="Dropdownlistseason",
    ),
    # Confirmed from GIU's authenticated EXTStudent/Home.aspx navigation menu.
    "giu": PortalSite(
        base_url="https://portal.giu-uni.de/GIUb",
        transcript_path="/EXTStudent/Transcript_m.aspx",
        prev_grades_path="/EXTStudent/CheckGradePreviousSemester_m.aspx",
        curr_grades_path="/EXTStudent/CheckGrade_m.aspx",
        season_suffix="ddl_season",
    ),
}
