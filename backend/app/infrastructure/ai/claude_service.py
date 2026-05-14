import json
from collections.abc import AsyncIterator
from datetime import date

import anthropic

from app.application.dto.ai_dto import DailyReviewDTO
from app.application.interfaces.ai_service import AIService
from app.config import settings
from app.domain.entities.baby import Baby
from app.domain.entities.chat_message import ChatMessage
from app.domain.entities.diaper import DiaperRecord
from app.domain.entities.feeding import Feeding
from app.domain.entities.play_record import PlayRecord
from app.domain.entities.sleep_record import SleepRecord
from app.infrastructure.ai.context_builder import build_daily_context, build_chat_context
from app.infrastructure.ai.prompts.pediatrician_system import PEDIATRICIAN_SYSTEM_PROMPT
from app.infrastructure.ai.prompts.daily_review_prompt import build_daily_review_prompt


class ClaudeService(AIService):
    def __init__(self) -> None:
        self._client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)

    async def generate_review(
        self,
        baby: Baby,
        feedings: list[Feeding],
        sleeps: list[SleepRecord],
        diapers: list[DiaperRecord],
        plays: list[PlayRecord],
    ) -> DailyReviewDTO:
        context = build_daily_context(baby, feedings, sleeps, diapers, plays)
        prompt = build_daily_review_prompt(context)

        message = await self._client.messages.create(
            model="claude-haiku-4-5",
            max_tokens=4096,
            system="당신은 신생아 육아 전문가입니다. JSON 형식으로만 응답하세요.",
            messages=[{"role": "user", "content": prompt}],
        )

        text = next(
            (block.text for block in message.content if block.type == "text"), "{}"
        )

        try:
            data = json.loads(text)
        except json.JSONDecodeError:
            start = text.find("{")
            end = text.rfind("}") + 1
            if start >= 0 and end > start:
                data = json.loads(text[start:end])
            else:
                data = {}

        return DailyReviewDTO(
            baby_id=baby.id,
            review_date=date.today(),
            feeding_analysis=data.get("feeding_analysis", "수유 데이터를 분석할 수 없습니다."),
            sleep_analysis=data.get("sleep_analysis", "수면 데이터를 분석할 수 없습니다."),
            diaper_analysis=data.get("diaper_analysis", "배변 데이터를 분석할 수 없습니다."),
            play_analysis=data.get("play_analysis", "놀이 데이터를 분석할 수 없습니다."),
            overall_assessment=data.get("overall_assessment", "종합 평가를 생성할 수 없습니다."),
            alerts=data.get("alerts", []),
            recommendations=data.get("recommendations", []),
        )

    async def chat_stream(
        self,
        baby: Baby,
        conversation_history: list[ChatMessage],
        user_message: str,
    ) -> AsyncIterator[str]:
        baby_context = build_chat_context(baby)
        system_prompt = f"{PEDIATRICIAN_SYSTEM_PROMPT}\n\n{baby_context}"

        messages = []
        for msg in conversation_history:
            messages.append({"role": msg.role, "content": msg.content})
        messages.append({"role": "user", "content": user_message})

        async def _stream() -> AsyncIterator[str]:
            async with self._client.messages.stream(
                model="claude-haiku-4-5",
                max_tokens=2048,
                system=system_prompt,
                messages=messages,
            ) as stream:
                async for text in stream.text_stream:
                    yield text

        return _stream()
