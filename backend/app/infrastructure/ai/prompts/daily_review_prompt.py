def build_daily_review_prompt(context: str) -> str:
    return f"""다음은 오늘 아기의 육아 기록입니다:

{context}

위 데이터를 바탕으로 다음 JSON 형식으로 오늘의 육아 리뷰를 작성해주세요:

{{
  "feeding_analysis": "수유 분석 (양, 횟수, 패턴에 대한 상세 분석)",
  "sleep_analysis": "수면 분석 (총 수면 시간, 패턴, 품질에 대한 분석)",
  "diaper_analysis": "배변 분석 (횟수, 색상, 상태에 대한 분석)",
  "play_analysis": "놀이 활동 분석 (활동 종류, 시간, 발달 적절성 분석)",
  "overall_assessment": "전반적인 오늘 하루 종합 평가",
  "alerts": ["주의가 필요한 사항들의 배열 (없으면 빈 배열)"],
  "recommendations": ["내일을 위한 권장 사항들의 배열"]
}}

JSON만 반환하고 다른 텍스트는 포함하지 마세요."""
