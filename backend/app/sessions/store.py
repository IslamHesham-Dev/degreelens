from __future__ import annotations

import hashlib
import secrets
import threading
import time
import uuid

from guc_portal import GucPortal

from app.academic import AcademicService
from app.sessions.models import StudentSession


class SessionStore:
    """In-memory, single-replica session store for the private prototype."""

    def __init__(
        self,
        *,
        ttl_minutes: int,
        current_season: str,
        advisory_year: str,
    ) -> None:
        self.ttl_seconds = ttl_minutes * 60
        self.current_season = current_season
        self.advisory_year = advisory_year
        self._sessions: dict[str, StudentSession] = {}
        self._lock = threading.RLock()

    @staticmethod
    def _digest(token: str) -> str:
        return hashlib.sha256(token.encode("utf-8")).hexdigest()

    def create(
        self,
        portal: GucPortal,
        *,
        enrollment_year: int | None = None,
        seasons: list[tuple[str, str]] | None = None,
    ) -> tuple[str, StudentSession]:
        token = secrets.token_urlsafe(40)
        now = time.time()
        session = StudentSession(
            session_id=str(uuid.uuid4()),
            portal=portal,
            academic=AcademicService(
                portal,
                current_season=self.current_season,
                advisory_year=self.advisory_year,
                enrollment_year=enrollment_year,
            ),
            created_at=now,
            expires_at=now + self.ttl_seconds,
        )
        if seasons is not None:
            session.academic.prime_seasons(seasons)
        with self._lock:
            self._purge_expired_locked(now)
            self._sessions[self._digest(token)] = session
        return token, session

    def get(self, token: str, *, touch: bool = True) -> StudentSession | None:
        now = time.time()
        digest = self._digest(token)
        with self._lock:
            self._purge_expired_locked(now)
            session = self._sessions.get(digest)
            if session and touch:
                session.expires_at = now + self.ttl_seconds
            return session

    def delete(self, token: str) -> bool:
        with self._lock:
            session = self._sessions.pop(self._digest(token), None)
        if session:
            session.close()
            return True
        return False

    def _purge_expired_locked(self, now: float) -> None:
        expired = [
            digest
            for digest, session in self._sessions.items()
            if session.expires_at <= now
        ]
        sessions = [self._sessions.pop(digest) for digest in expired]
        for session in sessions:
            session.close()

    def close_all(self) -> None:
        with self._lock:
            sessions = list(self._sessions.values())
            self._sessions.clear()
        for session in sessions:
            session.close()
