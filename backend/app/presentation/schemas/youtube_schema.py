"""YouTube 자막 관련 Pydantic 스키마."""

from pydantic import BaseModel, field_validator


class YouTubeTranscriptRequest(BaseModel):
    url: str

    @field_validator("url")
    @classmethod
    def must_be_youtube(cls, v: str) -> str:
        if "youtube.com" not in v and "youtu.be" not in v:
            raise ValueError("YouTube URL만 지원합니다.")
        return v


class YouTubeSummarizeRequest(BaseModel):
    url: str

    @field_validator("url")
    @classmethod
    def must_be_youtube(cls, v: str) -> str:
        if "youtube.com" not in v and "youtu.be" not in v:
            raise ValueError("YouTube URL만 지원합니다.")
        return v
