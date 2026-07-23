from app.config import get_settings
from app.sessions.store import SessionStore

settings = get_settings()

session_store = SessionStore(
    ttl_minutes=settings.session_ttl_minutes,
    current_season=settings.current_season,
    advisory_year=settings.advisory_year,
)
