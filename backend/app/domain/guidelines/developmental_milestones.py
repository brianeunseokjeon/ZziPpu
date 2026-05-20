"""
영유아 발달 단계 + 부모 행동 가이드.

이 파일은 AI 채팅·일일 리뷰 프롬프트와 발달 가이드 페이지가 공유하는 단일 출처.
출처 우선순위는 guideline_references.py와 동일:
  1. 대한소아청소년과학회 KPS / 질병관리청 / 보건복지부 K-DST
  2. AAP Bright Futures 4판 (2024), AASM, WHO

K-DST 6영역: 대근육 / 소근육 / 인지 / 언어 / 사회성 / 자조
"""
from dataclasses import dataclass, field
from typing import Literal


Priority = Literal["high", "medium", "low"]


@dataclass(frozen=True)
class ParentAction:
    """부모가 이 시기에 해줘야 할 행동."""
    icon: str
    title: str
    detail: str
    source: str            # "AAP / 대한소아청소년과학회" 같은 짧은 인용
    priority: Priority


@dataclass(frozen=True)
class DevelopmentStage:
    age_range_days: tuple[int, int]   # [start, end) — end는 다음 시기 시작
    label: str                         # "신생아기 (0~4주)"
    summary: str                       # 한 문장 요약
    # K-DST 6영역
    gross_motor: list[str] = field(default_factory=list)
    fine_motor: list[str] = field(default_factory=list)
    cognition: list[str] = field(default_factory=list)
    language: list[str] = field(default_factory=list)
    social: list[str] = field(default_factory=list)
    self_care: list[str] = field(default_factory=list)
    # 행동 가이드 / 위험 신호 / 일상 요약
    parent_actions: list[ParentAction] = field(default_factory=list)
    warning_signs: list[str] = field(default_factory=list)
    feeding_summary: str = ""
    sleep_summary: str = ""
    play_summary: str = ""
    sources: list[str] = field(default_factory=list)


# ── 출처 단축 ─────────────────────────────────────────────────────
KPS = "대한소아청소년과학회 KPS"
AAP = "AAP Bright Futures 4판 (2024)"
AAP_SAFE_SLEEP = "AAP Safe Sleep (2022, 2024 reaffirmed)"
AASM = "AASM Pediatric Sleep Consensus"
KDCA_VAX = "질병관리청 표준예방접종 (2026)"
KDST = "보건복지부 K-DST (2024)"


# ── 12개 시기 정의 ────────────────────────────────────────────────
DEVELOPMENT_STAGES: list[DevelopmentStage] = [
    # 1. 신생아기 (0~4주)
    DevelopmentStage(
        age_range_days=(0, 29),
        label="신생아기 (0~4주)",
        summary="아기와 부모 모두 적응하는 시기. 수유·수면·체온 안정이 최우선.",
        gross_motor=["굴곡 자세", "엎드린 자세에서 짧게 머리 들기"],
        fine_motor=["손에 닿는 자극에 반사적으로 잡기 (palmar grasp)"],
        cognition=["밝은 빛에 반응", "큰 소리에 놀람 반응"],
        language=["울음으로 욕구 표현"],
        social=["사람 얼굴 응시 시작 (2주~)"],
        self_care=["수유 시 강한 흡철 반사"],
        parent_actions=[
            ParentAction(
                icon="🤱",
                title="비타민 D 400IU/일 시작",
                detail="모유수유는 출생 직후부터, 분유는 하루 1L 미만 섭취 시 추가 보충",
                source=f"{AAP} · {KPS}",
                priority="high",
            ),
            ParentAction(
                icon="😴",
                title="등에 눕혀 재우기 (Back to Sleep)",
                detail="딱딱한 매트리스, 베개·이불·인형 제거. 같은 방 다른 침대(room-sharing) 권장.",
                source=AAP_SAFE_SLEEP,
                priority="high",
            ),
            ParentAction(
                icon="🤸",
                title="터미타임 시작",
                detail="깨어있을 때 2~3분씩 × 3~4회. 3개월에 누적 15~30분 목표.",
                source=AAP,
                priority="medium",
            ),
            ParentAction(
                icon="💉",
                title="BCG 접종 (생후 4주 이내)",
                detail="결핵 예방. 보건소 또는 지정 의료기관에서 접종.",
                source=KDCA_VAX,
                priority="high",
            ),
            ParentAction(
                icon="🩺",
                title="2주차 첫 신생아 진찰",
                detail="체중 회복 확인, 황달 평가, 수유 평가.",
                source=KPS,
                priority="medium",
            ),
        ],
        warning_signs=[
            "직장 체온 38℃ 이상 발열 (3개월 미만은 무조건 응급)",
            "황달이 2주 이상 지속되거나 더 진해짐",
            "수유 거부 8시간 이상, 처짐",
            "청색증(입술·손발 파랑), 무호흡 20초 이상",
            "분당 호흡 60회 이상, 갈비뼈 사이가 들어감",
        ],
        feeding_summary="분유 30~60ml × 2~3시간(하루 8~12회) / 모유 10~15분/측",
        sleep_summary="하루 14~17시간. 4~5시간 이상 연속 수면은 피하기 (수유 텀 유지)",
        play_summary="터미타임 누적 10분/일. 얼굴 응시·말 걸기로 언어 자극.",
        sources=[KPS, AAP, AAP_SAFE_SLEEP, KDCA_VAX],
    ),
    # 2. 1-2개월
    DevelopmentStage(
        age_range_days=(29, 61),
        label="생후 1~2개월",
        summary="첫 미소가 보이기 시작하는 시기. 시각·청각 발달 활발.",
        gross_motor=["엎드려서 잠깐 머리 들기"],
        fine_motor=["손을 펴서 가운데로 모으기"],
        cognition=["움직이는 물체 따라 보기"],
        language=["부드러운 발성 (cooing) 시작"],
        social=["사회적 미소 시작 (4~6주)"],
        self_care=["수유 텀 점차 길어짐"],
        parent_actions=[
            ParentAction(
                icon="🤱",
                title="비타민 D 400IU/일 지속",
                detail="모든 영아 권장 (모유·혼합·분유 무관 시 분유 1L 미만이면 보충).",
                source=f"{AAP} · {KPS}",
                priority="high",
            ),
            ParentAction(
                icon="😴",
                title="안전 수면 환경 유지",
                detail="등 눕혀 재우기, 베개/이불/인형 없음. 흔들기 절대 금지(SBS 위험).",
                source=AAP_SAFE_SLEEP,
                priority="high",
            ),
            ParentAction(
                icon="🤸",
                title="터미타임 누적 15~20분/일",
                detail="3~4회로 나누어 진행. 부모 가슴 위에서도 가능.",
                source=AAP,
                priority="medium",
            ),
            ParentAction(
                icon="🗣",
                title="얼굴 보고 말 걸기, 노래 부르기",
                detail="언어 자극은 출생 직후부터. 표정·억양을 풍부하게.",
                source=AAP,
                priority="medium",
            ),
        ],
        warning_signs=[
            "38℃ 이상 발열 (3개월 미만은 무조건 응급)",
            "수유량 급감, 처짐",
            "큰 소리에 전혀 놀라지 않음 (청력 의심)",
            "사회적 미소가 2개월에도 없음 (3개월까지 관찰)",
        ],
        feeding_summary="분유 60~120ml × 2.5~3.5시간 / 모유 8~10회/일",
        sleep_summary="하루 14~17시간. 야간 5~6시간 연속 수면 가능해지기 시작.",
        play_summary="얼굴 응시, 부드러운 색·소리 자극. 흑백 카드도 효과적.",
        sources=[KPS, AAP, AAP_SAFE_SLEEP],
    ),
    # 3. 2-3개월
    DevelopmentStage(
        age_range_days=(61, 91),
        label="생후 2~3개월",
        summary="목 가누기 시작, 옹알이 활발해지는 발달 폭발기.",
        gross_motor=["엎드려 가슴 들기", "목 가누기 시작 (~3개월 완성)"],
        fine_motor=["두 손을 가운데로 모아 놀기"],
        cognition=["얼굴·물체를 눈으로 추적"],
        language=["옹알이 활발 (다양한 모음)"],
        social=["사람을 향해 웃음, 얼굴 인식"],
        self_care=["수유 텀 3시간 안정화"],
        parent_actions=[
            ParentAction(
                icon="🤸",
                title="터미타임 누적 30분/일",
                detail="3~4회 분산. 장난감으로 흥미 유도. 머리·목 근육 발달 핵심.",
                source=AAP,
                priority="high",
            ),
            ParentAction(
                icon="🚫",
                title="이유식·꿀·생우유 절대 금지",
                detail="이유식은 6개월부터. 꿀은 12개월 이전 보툴리누스 독소 위험.",
                source=f"{AAP} · {KPS}",
                priority="high",
            ),
            ParentAction(
                icon="🗣",
                title="옹알이에 응답하기",
                detail="아기가 소리 내면 마치 대화하듯 반응. 언어 발달 핵심 자극.",
                source=AAP,
                priority="medium",
            ),
            ParentAction(
                icon="📚",
                title="그림책 읽어주기 시작",
                detail="흑백 또는 색 대비 강한 책. 부모 목소리 자체가 자극.",
                source=AAP,
                priority="low",
            ),
        ],
        warning_signs=[
            "3개월에도 목 가누기가 전혀 안 됨",
            "엎드린 자세에서 머리 들기 못함",
            "사회적 미소·소리 반응 전혀 없음",
            "한쪽 손·발만 사용하는 경향 (이 시기엔 양측 대칭)",
        ],
        feeding_summary="분유 90~150ml × 3~4시간 / 모유 6~8회/일",
        sleep_summary="하루 14~17시간. 야간 5~8시간 연속 수면 시작.",
        play_summary="터미타임, 얼굴 마주보고 노래·이야기, 거울 보기.",
        sources=[KPS, AAP, AAP_SAFE_SLEEP],
    ),
    # 4. 3-4개월
    DevelopmentStage(
        age_range_days=(91, 121),
        label="생후 3~4개월",
        summary="뒤집기 준비, 손으로 물건 잡기 시작. 활발한 상호작용기.",
        gross_motor=["목 완전히 가눔", "엎드려 팔로 상체 받치기"],
        fine_motor=["딸랑이 등 물건 잡기 시작"],
        cognition=["원인-결과 인식 시작 (흔들면 소리 남)"],
        language=["다양한 자음 시도 (ㄱ/ㅂ 등)", "웃음소리"],
        social=["부모에게 큰 반응, 낯선 사람도 미소"],
        self_care=["손을 입에 가져감"],
        parent_actions=[
            ParentAction(
                icon="🤸",
                title="터미타임 누적 30~60분/일",
                detail="뒤집기 준비. 손으로 물건 잡을 수 있는 위치에 장난감 배치.",
                source=AAP,
                priority="high",
            ),
            ParentAction(
                icon="⚠️",
                title="낙상 주의",
                detail="뒤집기 시작 직전. 침대·소파에 혼자 두지 않기.",
                source=KPS,
                priority="high",
            ),
            ParentAction(
                icon="🩺",
                title="2~4개월 영유아 건강검진 + 예방접종",
                detail="DTaP/IPV/Hib/PCV/로타바이러스 1차 (생후 2개월)",
                source=KDCA_VAX,
                priority="high",
            ),
            ParentAction(
                icon="🗣",
                title="다양한 소리 자극",
                detail="음악, 부모 노래, 일상 소리. 단조로운 환경 피하기.",
                source=AAP,
                priority="medium",
            ),
        ],
        warning_signs=[
            "4개월에도 목 가누기 불완전",
            "물건을 잡으려는 시도 전혀 없음",
            "소리 반응 없음 또는 한쪽만 반응",
            "사회적 미소·웃음 전혀 없음",
        ],
        feeding_summary="분유 120~180ml × 3.5~5시간 / 모유 5~7회/일",
        sleep_summary="하루 12~16시간. 야간 8~10시간 연속 수면 정착 시작.",
        play_summary="딸랑이·모빌·거울. 부모와 마주보는 시간이 가장 좋은 놀이.",
        sources=[KPS, AAP, KDCA_VAX],
    ),
    # 5. 4-6개월
    DevelopmentStage(
        age_range_days=(121, 181),
        label="생후 4~6개월",
        summary="뒤집기 완성, 이유식 시작 검토 시기.",
        gross_motor=["뒤집기 완성 (등→배, 배→등)", "받쳐주면 앉기"],
        fine_motor=["물건을 잡아 입으로 가져가기", "양손으로 옮기기"],
        cognition=["사라진 물건 다시 보면 흥미", "이름 부르면 돌아보기"],
        language=["옹알이 다양화 (자음+모음 조합)"],
        social=["자기 이름에 반응, 거울 속 자신에게 미소"],
        self_care=["젖병·숟가락 입으로 물기 가능"],
        parent_actions=[
            ParentAction(
                icon="🥄",
                title="이유식 6개월 시작 준비",
                detail="목 완전히 가눔 + 앉음 + 손을 입으로 + 음식 관심 = 시작 신호. 단일 식재료부터.",
                source=f"{AAP} · {KPS}",
                priority="high",
            ),
            ParentAction(
                icon="💉",
                title="DTaP/IPV/Hib/PCV/로타 2차 (4개월)",
                detail="2개월 1차 + 2개월 후 2차 접종.",
                source=KDCA_VAX,
                priority="high",
            ),
            ParentAction(
                icon="⚠️",
                title="낙상·삼킴 위험 본격화",
                detail="뒤집기로 침대 낙상 위험. 작은 물건 삼킴 주의.",
                source=KPS,
                priority="high",
            ),
            ParentAction(
                icon="🤸",
                title="자유롭게 바닥 놀이",
                detail="뒤집기·구르기 연습. 무게 실어 앉기 연습.",
                source=AAP,
                priority="medium",
            ),
        ],
        warning_signs=[
            "6개월에도 뒤집기 못함",
            "지지해도 앉기 어려움",
            "옹알이가 사라짐 (퇴행 의심)",
            "낯선 환경·소리에 전혀 반응 없음",
        ],
        feeding_summary="분유 120~180ml × 4~5시간 / 모유 5~6회/일 / 6개월 이유식 시작",
        sleep_summary="하루 12~16시간. 야간 8~10시간 연속, 낮잠 3~4회",
        play_summary="바닥 자유 놀이, 손 닿는 거리 장난감, 노래 부르기.",
        sources=[KPS, AAP, KDCA_VAX],
    ),
    # 6. 6-9개월
    DevelopmentStage(
        age_range_days=(181, 271),
        label="생후 6~9개월",
        summary="혼자 앉기, 이유식 진행, 낯가림 시작.",
        gross_motor=["혼자 앉기 (6~7개월)", "기기 준비 또는 시작"],
        fine_motor=["손에서 손으로 물건 옮기기", "엄지·검지로 잡기 시작"],
        cognition=["대상영속성 (까꿍 놀이 반응)"],
        language=["옹알이가 음절 반복 (마마, 바바)"],
        social=["낯가림 시작 (8~9개월 정점)", "분리불안 시작"],
        self_care=["손가락 음식 시도, 컵 보고 따라하기"],
        parent_actions=[
            ParentAction(
                icon="🥄",
                title="이유식 단계별 진행",
                detail="6개월: 미음·단일 식재료 / 7~8개월: 으깬 형태 / 9개월: 알갱이 있는 죽",
                source=f"{KPS} · {AAP}",
                priority="high",
            ),
            ParentAction(
                icon="🩸",
                title="모유수유 시 철분 보충",
                detail="AAP: 모유수유 영아 4~6개월부터 철분 1mg/kg/day. 이유식 철분 강화 식품으로도 가능.",
                source=AAP,
                priority="high",
            ),
            ParentAction(
                icon="⚠️",
                title="질식 위험 식품 금지",
                detail="견과류, 통포도, 사탕, 생당근, 팝콘. 작게 잘라도 위험.",
                source=AAP,
                priority="high",
            ),
            ParentAction(
                icon="💉",
                title="3차 접종 (6개월)",
                detail="DTaP·IPV·Hib·PCV 3차 + B형간염 3차 + 인플루엔자 1차(매년)",
                source=KDCA_VAX,
                priority="high",
            ),
            ParentAction(
                icon="🤸",
                title="혼자 앉기·기기 연습 환경",
                detail="안전한 바닥 공간 확보. 까꿍·짝짜꿍 놀이.",
                source=AAP,
                priority="medium",
            ),
        ],
        warning_signs=[
            "9개월에도 혼자 앉기 어려움",
            "옹알이가 멈춤 또는 단조로움",
            "이름 불러도 반응 없음",
            "한쪽 손·발만 쓰는 경향",
            "낯가림 전혀 없음 또는 너무 심한 분리불안",
        ],
        feeding_summary="분유 180~210ml × 4~5시간 + 이유식 1~2회 (철분 강화)",
        sleep_summary="하루 12~16시간. 낮잠 2~3회로 줄어듦.",
        play_summary="까꿍, 짝짜꿍, 거울 놀이, 그림책. 안전한 바닥 탐색.",
        sources=[KPS, AAP, KDCA_VAX],
    ),
    # 7. 9-12개월
    DevelopmentStage(
        age_range_days=(271, 365),
        label="생후 9~12개월",
        summary="잡고 서기, 첫 단어 시도, 자조 능력 시작.",
        gross_motor=["기기 활발", "잡고 서기", "잡고 옆걸음", "혼자 잠깐 서기"],
        fine_motor=["손가락 집기 (pincer grasp)", "물건 떨어뜨리고 줍기"],
        cognition=["원인-결과 이해 ('스위치 누르면 켜짐')"],
        language=["'엄마/아빠' 같은 의미 단어 시도 (1~2개)"],
        social=["손 흔들기, 안녕 표현, 흉내 내기"],
        self_care=["손가락 음식 스스로 먹기, 컵으로 마시기 시도"],
        parent_actions=[
            ParentAction(
                icon="🩺",
                title="9~12개월 영유아 건강검진 + K-DST 1차",
                detail="발달선별검사 + Hib·PCV 4차 + MMR 1차 + 수두 1차 + 일본뇌염 1차 (12개월)",
                source=f"{KDST} · {KDCA_VAX}",
                priority="high",
            ),
            ParentAction(
                icon="🚫",
                title="꿀·생우유·보행기 절대 금지",
                detail="꿀(보툴리누스), 생우유(철분 결핍·장출혈), 보행기(낙상·근육 발달 저해).",
                source=f"{KPS} · {AAP}",
                priority="high",
            ),
            ParentAction(
                icon="📚",
                title="그림책 매일 읽어주기",
                detail="이 시기 언어 노출이 어휘 발달 결정. 같은 책 반복도 좋음.",
                source=AAP,
                priority="medium",
            ),
            ParentAction(
                icon="🤲",
                title="자조 능력 격려",
                detail="손가락 음식 스스로 먹기, 컵으로 마시기 연습 (지저분해도 OK).",
                source=AAP,
                priority="medium",
            ),
        ],
        warning_signs=[
            "12개월에도 기지 못함 또는 잡고 서기 못함",
            "옹알이가 사라짐 또는 단어 시도 전혀 없음",
            "이름·간단한 지시('주세요')에 반응 없음",
            "양손 사용 비대칭 (한쪽만 우세)",
        ],
        feeding_summary="분유 180~210ml × 4~5시간 + 이유식 2~3회",
        sleep_summary="하루 12~16시간. 낮잠 2회로 정착.",
        play_summary="기기·잡고 서기 환경. 쌓기 컵·블록, 그림책, 신체 놀이.",
        sources=[KPS, AAP, KDST, KDCA_VAX],
    ),
    # 8. 12-15개월
    DevelopmentStage(
        age_range_days=(365, 456),
        label="생후 12~15개월 (1년~)",
        summary="첫 걸음, 첫 단어. 생우유 가능, 일반식 전환 시작.",
        gross_motor=["혼자 서기", "첫 걸음 (12~15개월)"],
        fine_motor=["블록 2개 쌓기", "숟가락 잡고 입에 가져가기"],
        cognition=["간단한 지시 이해 ('주세요', '여기 와')"],
        language=["의미 있는 단어 3~5개", "엄마·아빠 정확히 사용"],
        social=["부모 행동 흉내, 손 흔들기로 인사"],
        self_care=["컵으로 마시기, 숟가락 사용 시작"],
        parent_actions=[
            ParentAction(
                icon="🥛",
                title="생우유 시작 가능 (480~720ml/일)",
                detail="12개월부터 분유 대신 전유 가능. 하루 720ml 초과 시 철분 결핍 위험.",
                source=f"{AAP} · {KPS}",
                priority="high",
            ),
            ParentAction(
                icon="🍯",
                title="꿀 비로소 허용 (12개월 이후)",
                detail="이전 절대 금지였던 꿀 가능. 단 너무 단 음식은 충치 위험.",
                source=AAP,
                priority="medium",
            ),
            ParentAction(
                icon="🚶",
                title="안전한 걷기 환경",
                detail="모서리 보호, 계단 안전문, 미끄럼 방지. 보행기 여전히 금지.",
                source=KPS,
                priority="high",
            ),
            ParentAction(
                icon="📺",
                title="화면 노출 18개월 미만 금지",
                detail="화상통화 외 영상·앱 금지 (AAP Media Use). 양육자 상호작용이 핵심.",
                source=AAP,
                priority="high",
            ),
        ],
        warning_signs=[
            "15개월에도 의미 단어 1개도 없음",
            "혼자 서기·걸음 시도 전혀 없음",
            "이름 불러도 반응 거의 없음",
            "눈맞춤 회피, 흉내·손짓 없음",
        ],
        feeding_summary="생우유 480~720ml/일 + 일반식 3회 + 간식 1~2회",
        sleep_summary="하루 11~14시간. 낮잠 1~2회.",
        play_summary="블록 쌓기, 모양 맞추기, 그림책, 부모 행동 흉내내기.",
        sources=[KPS, AAP, KDST],
    ),
    # 9. 15-18개월
    DevelopmentStage(
        age_range_days=(456, 547),
        label="생후 15~18개월",
        summary="걷기 안정, 어휘 폭발 시작.",
        gross_motor=["혼자 걷기 안정", "계단 도움 받아 오르기"],
        fine_motor=["블록 3~4개 쌓기", "크레용으로 끄적이기"],
        cognition=["손가락으로 가리키기 (요구·관심 공유)"],
        language=["10~50개 단어 (18개월)"],
        social=["분리불안 점차 완화, 또래 관심"],
        self_care=["옷 벗기 도움 받기, 양치 따라하기"],
        parent_actions=[
            ParentAction(
                icon="💉",
                title="DTaP 4차 + 일본뇌염 2차",
                detail="15~18개월에 DTaP 4차. 일본뇌염 1차 후 1개월 뒤 2차.",
                source=KDCA_VAX,
                priority="high",
            ),
            ParentAction(
                icon="📚",
                title="매일 그림책 + 말 걸기",
                detail="어휘 폭발기. 일상 행동을 말로 설명. 같은 책 반복도 OK.",
                source=AAP,
                priority="high",
            ),
            ParentAction(
                icon="🦷",
                title="치아 관리 시작",
                detail="아침·자기 전 양치(쌀알만큼 불소치약). 생후 12개월부터 치과 검진 권장.",
                source=KPS,
                priority="medium",
            ),
            ParentAction(
                icon="🚫",
                title="화면 노출 여전히 최소화",
                detail="18개월까지 화상통화 외 금지. 시작하더라도 양육자 동반·양질 콘텐츠만.",
                source=AAP,
                priority="medium",
            ),
        ],
        warning_signs=[
            "18개월에도 단어 5개 미만",
            "혼자 걷기 못함",
            "손가락 가리키기·흉내내기 전혀 없음",
            "감정 표현 매우 단조롭거나 격해짐 지속",
        ],
        feeding_summary="일반식 3회 + 간식 1~2회. 생우유 480~720ml.",
        sleep_summary="하루 11~14시간. 낮잠 1회로 줄어듦.",
        play_summary="모래·물 놀이, 크레용, 따라 그리기, 신체 놀이.",
        sources=[KPS, AAP, KDCA_VAX],
    ),
    # 10. 18-24개월
    DevelopmentStage(
        age_range_days=(547, 730),
        label="생후 18~24개월 (2년~)",
        summary="두 단어 조합, 자아 형성기. K-DST 3차 발달검사 시기.",
        gross_motor=["뛰기 시도", "계단 잡고 오르내리기"],
        fine_motor=["블록 5~6개 쌓기", "숟가락 흘리지 않고 사용"],
        cognition=["역할 놀이 시작 ('전화 받는 척')"],
        language=["50~200개 단어, 두 단어 조합 ('엄마 가')"],
        social=["평행 놀이 (옆에서 따로 놀기)"],
        self_care=["혼자 컵으로 마시기, 양말 벗기"],
        parent_actions=[
            ParentAction(
                icon="🩺",
                title="K-DST 3차 발달검사 (18~24개월)",
                detail="보건소 또는 지정 의료기관에서 무료 검사. 미수령 시 별도 예약.",
                source=KDST,
                priority="high",
            ),
            ParentAction(
                icon="📺",
                title="화면 노출 시작 시 신중하게",
                detail="18개월 이후 시작해도 부모 동반·양질 영상 최대 60분/일.",
                source=AAP,
                priority="high",
            ),
            ParentAction(
                icon="🚽",
                title="배변 훈련 신호 관찰",
                detail="기저귀 젖음 호소, 일정 시간 마른 상태 유지 등 신호 보이면 시작. 일반적으로 18~30개월.",
                source=AAP,
                priority="medium",
            ),
            ParentAction(
                icon="🤝",
                title="감정·예의 가르치기",
                detail="'주세요/감사합니다' 가르치기. 떼쓰기는 정상 발달 — 안정적 대처.",
                source=KPS,
                priority="medium",
            ),
        ],
        warning_signs=[
            "24개월에도 단어 50개 미만 또는 두 단어 조합 못함",
            "안 걷거나 자주 넘어짐",
            "눈맞춤·이름 반응 없음, 또래·부모에게 무관심",
            "반복 행동(흔들기·줄세우기)이 두드러짐",
        ],
        feeding_summary="일반식 3회 + 간식 2회. 생우유 480ml 정도로 조정.",
        sleep_summary="하루 11~14시간. 낮잠 1회 (1~2시간).",
        play_summary="역할 놀이, 모래·물·찰흙, 그림 그리기, 또래 옆 놀이.",
        sources=[KPS, AAP, KDST],
    ),
    # 11. 24-36개월
    DevelopmentStage(
        age_range_days=(730, 1096),
        label="생후 2~3년",
        summary="문장 구사, 협동 놀이 준비. 자율성·고집의 시기.",
        gross_motor=["달리기", "계단 혼자 오르기", "공 차기"],
        fine_motor=["블록 8개 이상 쌓기", "원 따라 그리기"],
        cognition=["3가지 색 구분", "큰/작은 비교"],
        language=["3~4단어 문장, 200~1000개 단어"],
        social=["또래와 일부 공유 시작, 자기 주장 강함"],
        self_care=["혼자 손 씻기, 신발 신기 시도, 배변 훈련 중"],
        parent_actions=[
            ParentAction(
                icon="🩺",
                title="K-DST 4차 발달검사 (30~36개월)",
                detail="이 시기 미수령은 발달지연 조기 발견 핵심 기회 — 꼭 받기.",
                source=KDST,
                priority="high",
            ),
            ParentAction(
                icon="📺",
                title="화면 노출 최대 1시간/일",
                detail="가능하면 부모 동반 시청. 영상보다 책·놀이 우선.",
                source=AAP,
                priority="medium",
            ),
            ParentAction(
                icon="🦷",
                title="치과 정기 검진",
                detail="6개월마다 치과 검진. 불소 도포 검토.",
                source=KPS,
                priority="medium",
            ),
            ParentAction(
                icon="🤗",
                title="감정 표현 가르치기",
                detail="'화났구나', '슬프구나' 식으로 감정에 이름 붙여주기. 떼쓰기 정상.",
                source=AAP,
                priority="medium",
            ),
        ],
        warning_signs=[
            "3년에도 두 단어 문장 못함",
            "발음이 가족 외에 전혀 알아들을 수 없음",
            "협동·역할 놀이 전혀 없음",
            "특정 자극에 과민·둔감",
        ],
        feeding_summary="일반식 3회 + 간식 2회. 다양한 식재료 도입.",
        sleep_summary="하루 10~13시간. 낮잠 1회 또는 생략.",
        play_summary="역할 놀이, 그림 그리기, 신체 활동, 또래 만남.",
        sources=[KPS, AAP, KDST],
    ),
    # 12. 36개월+
    DevelopmentStage(
        age_range_days=(1096, 99999),
        label="만 3세 이상",
        summary="유치원 준비기. K-DST 5~8차 검사 시기.",
        gross_motor=["한 발로 잠깐 서기", "세발자전거"],
        fine_motor=["가위 사용 시작", "원·사람 형태 그리기"],
        cognition=["수 세기 (1~10)", "이름·나이 말하기"],
        language=["4~5단어 문장, 1000개 이상 단어"],
        social=["역할·협동 놀이, 친구 개념 형성"],
        self_care=["혼자 옷 입기·벗기, 화장실 사용"],
        parent_actions=[
            ParentAction(
                icon="🩺",
                title="K-DST 5~8차 검사 + 만 4~6세 추가접종",
                detail="DTaP 5차, IPV 4차, MMR 2차, 일본뇌염 4차.",
                source=f"{KDST} · {KDCA_VAX}",
                priority="high",
            ),
            ParentAction(
                icon="📚",
                title="문해력 기초 — 매일 책 읽기",
                detail="이 시기 부모 음독이 평생 독서 습관 결정.",
                source=AAP,
                priority="high",
            ),
            ParentAction(
                icon="🍎",
                title="비만 예방 식습관",
                detail="과당 음료 피하기. 가공식품 최소화. 가족과 함께 식사.",
                source=KPS,
                priority="medium",
            ),
        ],
        warning_signs=[
            "5세에도 발음이 가족 외에 안 통함",
            "친구 만들기·역할 놀이 전혀 없음",
            "30분 이상 집중 못함 (지속)",
        ],
        feeding_summary="일반식 3회 + 간식 2회. 가족과 함께 식사 습관.",
        sleep_summary="하루 10~13시간 (만 3~5세).",
        play_summary="협동 놀이, 그림·만들기, 신체 활동, 책 읽기.",
        sources=[KPS, AAP, KDST, KDCA_VAX],
    ),
]


# ── 조회 함수 ─────────────────────────────────────────────────────

def get_stage_for_age_days(age_days: int) -> DevelopmentStage:
    """주어진 생후 일수에 해당하는 발달 단계 반환."""
    for stage in DEVELOPMENT_STAGES:
        start, end = stage.age_range_days
        if start <= age_days < end:
            return stage
    return DEVELOPMENT_STAGES[-1]


def get_neighboring_stages(age_days: int) -> tuple[DevelopmentStage | None, DevelopmentStage, DevelopmentStage | None]:
    """(이전, 현재, 다음) 시기 반환. 처음/마지막이면 None."""
    current = get_stage_for_age_days(age_days)
    idx = DEVELOPMENT_STAGES.index(current)
    prev = DEVELOPMENT_STAGES[idx - 1] if idx > 0 else None
    nxt = DEVELOPMENT_STAGES[idx + 1] if idx < len(DEVELOPMENT_STAGES) - 1 else None
    return prev, current, nxt


# ── 마일스톤 (날짜 계산기용) ──────────────────────────────────────

@dataclass(frozen=True)
class Milestone:
    days: int
    label: str
    emoji: str
    category: Literal["celebration", "checkup", "developmental"]
    description: str


MILESTONES: list[Milestone] = [
    Milestone(7, "1주", "🌱", "developmental", "신생아 적응기 시작"),
    Milestone(14, "2주", "🩺", "checkup", "신생아 첫 진찰 권장"),
    Milestone(30, "1개월", "🍼", "celebration", "한국 전통 첫 마지"),
    Milestone(50, "50일", "🎈", "celebration", "50일 기념"),
    Milestone(100, "백일", "💯", "celebration", "전통 백일 축하"),
    Milestone(120, "4개월 검진", "🩺", "checkup", "영유아 건강검진 + 예방접종 2차"),
    Milestone(180, "6개월", "🥄", "developmental", "이유식 시작 권장 시기"),
    Milestone(200, "200일", "🎊", "celebration", "200일 기념"),
    Milestone(270, "9개월", "🩺", "checkup", "영유아 건강검진 2차"),
    Milestone(300, "300일", "🎉", "celebration", "300일 기념"),
    Milestone(365, "돌 (1년)", "🎂", "celebration", "전통 돌잔치 · K-DST 1차 발달검사"),
    Milestone(500, "500일", "✨", "celebration", "500일 기념"),
    Milestone(540, "18개월 검진", "🩺", "checkup", "영유아 건강검진 3차"),
    Milestone(730, "두 돌 (2년)", "🎂", "celebration", "K-DST 3차 발달검사 시기"),
    Milestone(1095, "세 돌 (3년)", "🎂", "celebration", "K-DST 4차 발달검사 시기"),
]
