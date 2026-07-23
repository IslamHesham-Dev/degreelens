from __future__ import annotations

from pydantic import BaseModel, Field, SecretStr


class LoginRequest(BaseModel):
    username: str = Field(min_length=1, max_length=160)
    password: SecretStr


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_seconds: int
    current_season: str
    advisory_year: str


class SessionResponse(BaseModel):
    authenticated: bool
    expires_in_seconds: int
    current_season: str
    advisory_year: str


class MessageResponse(BaseModel):
    message: str
