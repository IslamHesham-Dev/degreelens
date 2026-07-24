from __future__ import annotations

from pydantic import BaseModel, Field, SecretStr


class LoginRequest(BaseModel):
    username: str = Field(min_length=1, max_length=160)
    password: SecretStr
    enrollment_year: int = Field(ge=2000, le=2100)


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_seconds: int
    current_season: str
    advisory_year: str
    enrollment_year: int
    transcript_years: list[str]


class SessionResponse(BaseModel):
    authenticated: bool
    expires_in_seconds: int
    current_season: str
    advisory_year: str
    enrollment_year: int
    transcript_years: list[str]


class MessageResponse(BaseModel):
    message: str
