from __future__ import annotations

import threading
import time
from dataclasses import dataclass, field
from typing import Any

from guc_portal import GucPortal

from app.academic import AcademicService


@dataclass
class StudentSession:
    session_id: str
    portal: GucPortal
    academic: AcademicService
    created_at: float
    expires_at: float
    conversation: list[Any] = field(default_factory=list)
    agent: Any = None
    chat_lock: threading.RLock = field(default_factory=threading.RLock)

    @property
    def expires_in_seconds(self) -> int:
        return max(0, int(self.expires_at - time.time()))

    def close(self) -> None:
        self.conversation.clear()
        self.agent = None
        self.academic.clear_cache()
        self.portal.session.auth = None
        self.portal.session.close()
