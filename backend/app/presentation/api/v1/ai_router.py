import json
from collections.abc import AsyncIterator
from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse

from app.application.use_cases.ai import (
    GenerateDailyReviewUseCase,
    ChatWithPediatricianUseCase,
    SaveChatInfoUseCase,
)
from app.domain.entities.chat_message import ChatMessage
from app.infrastructure.persistence.repositories import ChatRepositoryImpl
from app.presentation.dependencies import (
    CurrentUserDep,
    get_generate_review_use_case,
    get_chat_use_case,
    get_save_info_use_case,
    get_chat_repo,
)
from app.presentation.schemas.ai_schema import (
    DailyReviewRequest,
    DailyReviewResponse,
    ChatRequest,
    SaveInfoRequest,
    SavedInfoResponse,
)

router = APIRouter(prefix="/babies/{baby_id}/ai", tags=["ai"])


@router.post("/review", response_model=DailyReviewResponse)
async def generate_review(
    baby_id: UUID,
    body: DailyReviewRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[GenerateDailyReviewUseCase, Depends(get_generate_review_use_case)],
) -> DailyReviewResponse:
    try:
        result = await use_case.execute(baby_id, body.review_date)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    return DailyReviewResponse(
        baby_id=result.baby_id,
        review_date=result.review_date,
        feeding_analysis=result.feeding_analysis,
        sleep_analysis=result.sleep_analysis,
        diaper_analysis=result.diaper_analysis,
        play_analysis=result.play_analysis,
        overall_assessment=result.overall_assessment,
        alerts=result.alerts,
        recommendations=result.recommendations,
    )


@router.post("/chat")
async def chat_with_pediatrician(
    baby_id: UUID,
    body: ChatRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[ChatWithPediatricianUseCase, Depends(get_chat_use_case)],
    chat_repo: Annotated[ChatRepositoryImpl, Depends(get_chat_repo)],
) -> StreamingResponse:
    try:
        conversation_id, stream = await use_case.execute(
            baby_id=baby_id,
            conversation_id=body.conversation_id,
            user_message=body.message,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

    async def event_generator() -> AsyncIterator[str]:
        full_response = []
        conv_id_sent = False

        async for chunk in await stream:
            full_response.append(chunk)
            if not conv_id_sent:
                meta = json.dumps({"conversation_id": str(conversation_id)})
                yield f"data: {meta}\n\n"
                conv_id_sent = True
            yield f"data: {json.dumps({'chunk': chunk})}\n\n"

        complete_message = "".join(full_response)
        assistant_msg = ChatMessage(
            id=uuid4(),
            baby_id=baby_id,
            conversation_id=conversation_id,
            role="assistant",
            content=complete_message,
            created_at=datetime.now(timezone.utc),
        )
        await chat_repo.save_message(assistant_msg)
        yield f"data: {json.dumps({'done': True, 'conversation_id': str(conversation_id)})}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("/saved-info", response_model=SavedInfoResponse, status_code=status.HTTP_201_CREATED)
async def save_info(
    baby_id: UUID,
    body: SaveInfoRequest,
    user_id: CurrentUserDep,
    use_case: Annotated[SaveChatInfoUseCase, Depends(get_save_info_use_case)],
) -> SavedInfoResponse:
    result = await use_case.execute(
        baby_id=baby_id,
        title=body.title,
        content=body.content,
        category=body.category,
        chat_message_id=body.chat_message_id,
    )
    return SavedInfoResponse(
        id=result.id,
        baby_id=result.baby_id,
        title=result.title,
        content=result.content,
        category=result.category,
        chat_message_id=result.chat_message_id,
        created_at=result.created_at.isoformat(),
    )
