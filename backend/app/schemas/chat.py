from __future__ import annotations

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)


class ToolEvent(BaseModel):
    name: str
    status: str = "completed"


class ChatResponse(BaseModel):
    answer: str
    tools: list[ToolEvent]
    sources: list[str]
