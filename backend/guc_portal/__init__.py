"""guc_portal: a tiny Python client for the GUC student portal (SIS).

    from guc_portal import GucPortal

    portal = GucPortal("your.username", "your.password")  # or GUC_USERNAME / GUC_PASSWORD
    t = portal.get_transcript()
    print("GPA:", t.cumulative_gpa)
    for semester, rows in t.by_semester().items():
        print(semester)
        for r in rows:
            print(" ", r.grade, r.course)

Like the CMS client, this returns plain dataclasses so wrapping it as agent
tools later is a small job. It only reads; it never submits anything.
"""

from .client import BASE_URL, GucPortal
from .models import CourseGrades, GradeItem, Transcript, TranscriptRow

__all__ = [
    "GucPortal",
    "Transcript",
    "TranscriptRow",
    "CourseGrades",
    "GradeItem",
    "BASE_URL",
]
