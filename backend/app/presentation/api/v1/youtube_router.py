"""YouTube 자막 다운로드 + AI 요약 라우터."""

from __future__ import annotations

import json
from typing import AsyncIterator

import anthropic
from fastapi import APIRouter, HTTPException, status
from fastapi.responses import Response, StreamingResponse

from app.config import settings
from app.infrastructure.youtube.transcript_fetcher import (
    extract_video_id,
    fetch_transcript_text,
)
from app.presentation.dependencies import CurrentUserDep
from app.presentation.schemas.youtube_schema import (
    YouTubeSummarizeRequest,
    YouTubeTranscriptRequest,
)

router = APIRouter(prefix="/youtube", tags=["youtube"])

YOUTUBE_SUMMARY_SYSTEM_PROMPT = """당신은 유튜브 영상 자막을 분석하여 핵심 내용을 한국어로 요약하는 전문가입니다.

요약 규칙:
1. 내용을 논리적 섹션으로 나누어 ## 타이틀을 붙이세요
2. 각 섹션에는 해당 내용을 빠짐없이 서술하세요 (글자수 제한 없음)
3. 핵심 용어, 수치, 예시는 반드시 포함하세요
4. 영어 자막이면 한국어로 번역하여 요약하세요
5. 마지막에 ## 핵심 요약 섹션으로 3~5줄 요약을 추가하세요"""


@router.post("/transcript")
async def download_transcript(
    body: YouTubeTranscriptRequest,
    user_id: CurrentUserDep,
) -> Response:
    """YouTube 자막을 .txt 파일로 반환한다."""
    try:
        video_id = extract_video_id(body.url)
        text = fetch_transcript_text(video_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    return Response(
        content=text.encode("utf-8"),
        media_type="text/plain; charset=utf-8",
        headers={
            "Content-Disposition": f'attachment; filename="{video_id}_transcript.txt"',
            "Access-Control-Expose-Headers": "Content-Disposition",
        },
    )


@router.post("/summarize")
async def summarize_transcript(
    body: YouTubeSummarizeRequest,
    user_id: CurrentUserDep,
) -> StreamingResponse:
    """YouTube 자막을 fetch하여 Claude로 섹션별 요약을 스트리밍 반환한다."""
    try:
        video_id = extract_video_id(body.url)
        transcript = fetch_transcript_text(video_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)

    async def event_generator() -> AsyncIterator[str]:
        try:
            async with client.messages.stream(
                model="claude-opus-4-5",
                max_tokens=8192,
                system=YOUTUBE_SUMMARY_SYSTEM_PROMPT,
                messages=[
                    {
                        "role": "user",
                        "content": f"다음 유튜브 영상 자막을 요약해주세요:\n\n{transcript}",
                    }
                ],
            ) as stream:
                async for text in stream.text_stream:
                    yield f"data: {json.dumps({'chunk': text})}\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"
        finally:
            yield f"data: {json.dumps({'done': True})}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )
