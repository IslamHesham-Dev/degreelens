# API contract

All authenticated routes use:

```http
Authorization: Bearer <opaque-session-token>
```

## Authentication

- `POST /v1/auth/login`
- `GET /v1/auth/session`
- `POST /v1/auth/logout`

## Academic data

- `GET /v1/academic/context`
- `POST /v1/academic/advisory-semester` with
  `{"current_season": "Winter 2024"}`
- `GET /v1/academic/seasons`
- `GET /v1/academic/courses?season=Winter%202024`
- `GET /v1/academic/course-grades?course=ICS501`
- `GET /v1/academic/transcript-years`
- `GET /v1/academic/transcript?year=2024-2025`
- `POST /v1/academic/cache/clear`

## Advisor

- `POST /v1/chat`
- `POST /v1/chat/reset`

Chat responses include the answer, completed tool names, and human-readable
source labels so the mobile interface can distinguish portal facts from advice.
