# Architecture

```text
Flutter UI
  -> HTTPS JSON API
FastAPI
  -> opaque session token -> isolated StudentSession
  -> DegreeLens agent -> per-session academic tools/cache
  -> GucPortal -> GIU read-only pages
```

## Mobile

The Flutter app separates:

- UI screens and reusable visual components
- API services and JSON models
- authentication, academic, and advisor repositories
- secure device storage for only the opaque DegreeLens session token

The app contains no GIU credentials and no Anthropic key.

## Backend

Every successful login creates a separate `StudentSession` containing:

- one authenticated `GucPortal`
- one `AcademicService` and cache
- one agent conversation
- a short expiry and revocable random token

Only a SHA-256 digest of the opaque token is stored in the server lookup table.
Sessions are serialized per chat, and portal access is locked because the
underlying `requests.Session` is stateful.

## Scaling boundary

The initial deployment deliberately uses one process. Multiple workers would
not share in-memory sessions. A later multi-instance release needs a shared
encrypted session design or an official university authentication/API flow.
