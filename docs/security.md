# Security decisions

- GIU credentials are never compiled into Flutter.
- The Anthropic key remains only on the backend.
- Login and all authenticated requests require HTTPS outside local development.
- Request bodies and passwords must never be logged.
- Portal objects, caches, and conversations are isolated per session.
- Opaque tokens are random, revocable, short-lived, and stored as digests.
- Flutter stores only the opaque session token in platform secure storage.
- Logout and expiration close the portal connection and clear credential
  material, cached academic data, and conversation state.
- CMS is intentionally unavailable.

This is a private prototype, not an official university service. A public
multi-student release should obtain university approval and ideally use an
official delegated authentication/API flow instead of collecting portal
passwords.
