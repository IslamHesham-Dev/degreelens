from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.concurrency import run_in_threadpool
from langchain_core.messages import HumanMessage

from app.agent.factory import (
    build_agent,
    message_text,
    tool_events,
)
from app.config import get_settings
from app.schemas.auth import MessageResponse
from app.schemas.chat import ChatRequest, ChatResponse
from app.sessions.models import StudentSession
from app.dependencies import get_student_session

router = APIRouter(prefix="/chat", tags=["advisor"])


@router.post("", response_model=ChatResponse)
async def chat(
    payload: ChatRequest,
    student: StudentSession = Depends(get_student_session),
) -> ChatResponse:
    settings = get_settings()

    def invoke() -> ChatResponse:
        with student.chat_lock:
            if student.agent is None:
                student.agent = build_agent(student, settings)
            start = len(student.conversation)
            result = student.agent.invoke(
                {
                    "messages": [
                        *student.conversation,
                        HumanMessage(payload.message.strip()),
                    ]
                }
            )
            student.conversation = result["messages"]
            new_messages = student.conversation[start:]
            answer = message_text(student.conversation[-1].content)
            events, sources = tool_events(new_messages)
            return ChatResponse(
                answer=answer,
                tools=events,
                sources=sources,
            )

    try:
        return await run_in_threadpool(invoke)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from None
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="The academic advisor could not complete this request.",
        ) from None


@router.post("/reset", response_model=MessageResponse)
def reset_chat(
    student: StudentSession = Depends(get_student_session),
) -> MessageResponse:
    with student.chat_lock:
        student.conversation.clear()
    return MessageResponse(message="Advisory conversation reset.")
