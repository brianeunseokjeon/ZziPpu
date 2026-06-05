import json
from collections.abc import AsyncIterator
from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse

from app.application.use_cases.ai import (
    ChatWithPediatricianUseCase,
    DeleteSavedInfoUseCase,
    GenerateDailyReviewUseCase,
    ListSavedInfosUseCase,
    SaveChatInfoUseCase,
)
from app.domain.entities.chat_message import ChatMessage
from app.infrastructure.persistence.repositories import (
    AIReviewRepositoryImpl,
    ChatRepositoryImpl,
)
from app.presentation.dependencies import (
    CurrentUserDep,
    get_ai_review_repo,
    get_chat_repo,
    get_chat_use_case,
    get_delete_saved_info_use_case,
    get_generate_review_use_case,
    get_list_saved_infos_use_case,
    get_save_info_use_case,
)
from app.presentation.schemas.ai_schema import (
    ChatRequest,
    DailyReviewRequest,
    DailyReviewResponse,
    SavedInfoResponse,
    SaveInfoRequest,
)

router = APIRouter(prefix="/babies/{baby_id}/ai", tags=["ai"])


def _to_review_response(result) -> DailyReviewResponse:
    return DailyReviewResponse(
        baby_id=result.baby_id,
        review_date=result.review_date,
        feeding_analysis=result.feeding_analysis,
        sleep_analysis=result.sleep_analysis,
        diaper_analysis=result.diaper_analysis,
        play_analysis=result.play_analysis,
        overall_assessment=result.overall_assessment,
        alerts=list(result.alerts or []),
        recommendations=list(result.recommendations or []),
        positives=list(getattr(result, "positives", []) or []),
        considerations=list(getattr(result, "considerations", []) or []),
        concerns=list(getattr(result, "concerns", []) or []),
        critical_warnings=list(getattr(result, "critical_warnings", []) or []),
    )


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
    return _to_review_response(result)


@router.get("/reviews", response_model=list[DailyReviewResponse])
async def list_reviews(
    baby_id: UUID,
    user_id: CurrentUserDep,
    ai_review_repo: Annotated[AIReviewRepositoryImpl, Depends(get_ai_review_repo)],
    limit: int = 30,
) -> list[DailyReviewResponse]:
    """저장된 일일 AI 리뷰 목록 (최신순)."""
    reviews = await ai_review_repo.get_recent(baby_id, limit=limit)
    return [_to_review_response(r) for r in reviews]


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
            chat_date=body.chat_date,
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
    return _to_saved_info_response(result)


def _to_saved_info_response(info) -> SavedInfoResponse:
    return SavedInfoResponse(
        id=info.id,
        baby_id=info.baby_id,
        title=info.title,
        content=info.content,
        category=info.category,
        chat_message_id=info.chat_message_id,
        created_at=info.created_at.isoformat(),
    )


@router.get("/saved-info", response_model=list[SavedInfoResponse])
async def list_saved_infos(
    baby_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[ListSavedInfosUseCase, Depends(get_list_saved_infos_use_case)],
) -> list[SavedInfoResponse]:
    infos = await use_case.execute(baby_id)
    return [_to_saved_info_response(i) for i in infos]


@router.delete("/saved-info/{info_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_saved_info(
    baby_id: UUID,
    info_id: UUID,
    user_id: CurrentUserDep,
    use_case: Annotated[DeleteSavedInfoUseCase, Depends(get_delete_saved_info_use_case)],
) -> None:
    try:
        await use_case.execute(info_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
