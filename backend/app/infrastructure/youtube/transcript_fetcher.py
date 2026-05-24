"""YouTube 자막 추출 유틸리티."""

from __future__ import annotations

import re

from youtube_transcript_api import (
    NoTranscriptFound,
    TranscriptsDisabled,
    VideoUnavailable,
    YouTubeTranscriptApi,
)


def extract_video_id(url: str) -> str:
    """YouTube URL에서 영상 ID(11자)를 추출한다.

    지원 형식:
    - https://www.youtube.com/watch?v=XXXXXXXXXXX
    - https://youtu.be/XXXXXXXXXXX
    - https://youtube.com/shorts/XXXXXXXXXXX
    """
    patterns = [
        r"(?:v=)([A-Za-z0-9_-]{11})",
        r"youtu\.be/([A-Za-z0-9_-]{11})",
        r"shorts/([A-Za-z0-9_-]{11})",
    ]
    for pattern in patterns:
        if m := re.search(pattern, url):
            return m.group(1)
    raise ValueError("유효한 YouTube URL이 아닙니다. watch?v=, youtu.be/, shorts/ 형식을 지원합니다.")


def fetch_transcript_text(video_id: str) -> str:
    """YouTube 영상의 자막을 평문 텍스트로 반환한다.

    우선순위: 한국어 수동 자막 → 영어 수동 자막 → 자동 생성 자막 (ko → en 순)

    Raises:
        ValueError: 자막이 없거나 접근 불가한 경우
    """
    try:
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
    except VideoUnavailable:
        raise ValueError("비공개이거나 삭제된 영상입니다.")
    except TranscriptsDisabled:
        raise ValueError("이 영상은 자막이 비활성화되어 있습니다.")
    except Exception as e:
        raise ValueError(f"영상 정보를 가져올 수 없습니다: {e}") from e

    # 수동 자막 우선, 없으면 자동 생성 자막
    try:
        transcript = transcript_list.find_transcript(["ko", "en"])
    except NoTranscriptFound:
        try:
            transcript = transcript_list.find_generated_transcript(["ko", "en"])
        except NoTranscriptFound:
            raise ValueError(
                "이 영상에는 자막이 없습니다. 한국어 또는 영어 자막이 있는 영상을 입력해주세요."
            )

    try:
        entries = transcript.fetch()
    except Exception as e:
        raise ValueError(f"자막을 가져오는 중 오류가 발생했습니다: {e}") from e

    lines = [entry["text"].strip() for entry in entries if entry["text"].strip()]
    return "\n".join(lines)
