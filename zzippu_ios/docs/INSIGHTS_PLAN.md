# INSIGHTS_PLAN — 대시보드 "한눈 분석 + 소아과 가이드 비교" 기획

> 목표: 기록(수유·수면·기저귀·성장)을 애플 건강앱/구글 피트니스 감성으로 한눈에 분석하고,
> AAP·WHO·대한소아청소년과학회 가이드 범위와 비교해 "잘 먹고·자고·싸는지"를 상태 pill + 부드러운 코멘트로 보여준다.
> 원칙: 가이드=Data 번들(JSON), 비교=UseCase 순수, UI=Feature+DesignSystem. 의학적 신중(출처·면책·비단정 톤).

---

## 0. 기존 자산 (재사용 — 신규 개발 금지)

| 자산 | 위치 | 상태 |
|---|---|---|
| MetricCard·상세차트·성장곡선 | `Feature/Dashboard/{MetricCard,MetricDetailView,GrowthDetailView,SparklineChart}.swift` | 있음 |
| `FeedingAdequacyCard` (AAP 수유 게이지) | `Feature/Dashboard/DashboardSummaryCards.swift:64` | **하드코딩 450~600ml** → 가이드 데이터·체중 연동으로 교체 |
| `ComputeTrendUseCase` (일/주/월 버킷·평균·인사이트문구) | `Domain/UseCases/ComputeTrendUseCase.swift` | 있음, 밴드 비교 로직 추가 |
| `ComputeDashboardSummaryUseCase` (오늘 총량 집계) | `Domain/UseCases/ComputeDashboardSummaryUseCase.swift` | 있음, 그대로 입력원 |
| DS: DSCard·DSGaugeBar(normalRange 지원)·DSStatusPill·DSSectionHeader·DSChip·DSBadge | `Shared/DesignSystem/Components/` | 있음 |
| `StatusTone { success, warning, danger, info }` | `Shared/DesignSystem/Theme/Theme.swift:291` | 있음 |
| WHO 밴드 자리 예약 (AreaMark TODO) | `GrowthDetailView.swift:74` | **예약만 됨** → 데이터+오버레이 구현 |
| 웹 가이드/집계 로직 (이관 원본) | `frontend/.../feedingGuideline.ts`, `trends/lib/{guidelines,trendCalc}.ts` | 규칙·문구 이관·확장 |

**핵심 결정:** 웹의 `feedingGuideline.ts`(체중×150~180, cap 960, ±20%)·`guidelines.ts`(수면 NSF/AASM, 터미타임)·문구를 iOS로 이관하되,
분산된 하드코딩 대신 **단일 번들 JSON + 로더 + 순수 UseCase**로 격리한다.

---

## A. 가이드 데이터 (번들 정적 JSON) — `Resources/Guidelines/pediatric_guidelines.json`

Data 레이어 로더 `PediatricGuidelineRepository`가 로드·격리(Domain은 프로토콜만 의존).
연령은 **개월(months) 구간 [minInclusive, maxExclusive)** 로 정의. 수유량은 체중 파생이라 구간표 대신 계수로 둔다.

### 스키마
```jsonc
{
  "version": "2026-07",
  "disclaimer": "참고용 가이드입니다. 의학적 진단이 아니며 개인차는 정상입니다. 이상이 있으면 소아과 상담을 권장드려요.",
  "feeding": {                          // 체중 파생 (구간 무관)
    "mlPerKgMin": 150, "mlPerKgMax": 180,
    "dailyCapMl": 960, "tolerance": 0.20,
    "source": "AAP / HealthyChildren.org — Amount and Schedule of Formula Feedings",
    "note": "분유(formula) 기준. 모유수유는 양 측정이 어려워 비교에서 제외."
  },
  "sleep": [                            // 하루 총 수면시간(h, 낮잠 포함)
    { "minM": 0,  "maxM": 4,  "minH": 14, "maxH": 17, "label": "신생아" },
    { "minM": 4,  "maxM": 12, "minH": 12, "maxH": 16, "label": "영아" },
    { "minM": 12, "maxM": 24, "minH": 11, "maxH": 14, "label": "유아" }
  ],
  "diaper": [                           // 하루 소변 횟수 하한 + 대변 참고범위
    { "minM": 0,  "maxM": 1,  "peeMin": 6, "poopMin": 3, "poopMax": 12, "label": "생후 1주~1개월" },
    { "minM": 1,  "maxM": 6,  "peeMin": 6, "poopMin": 1, "poopMax": 8,  "label": "1~6개월" },
    { "minM": 6,  "maxM": 24, "peeMin": 5, "poopMin": 1, "poopMax": 4,  "label": "6개월+" }
  ],
  "tummyTime": [                        // 분/일 (깨어있을 때 누적)
    { "minM": 0, "maxM": 2, "minMin": 5,  "targetMin": 15 },
    { "minM": 2, "maxM": 4, "minMin": 20, "targetMin": 30 },
    { "minM": 4, "maxM": 6, "minMin": 30, "targetMin": 60 },
    { "minM": 6, "maxM": 24,"minMin": 60, "targetMin": 90 }
  ],
  "sources": {
    "sleep":  "NSF 2015 (Hirshkowitz) / AASM 2016 (Paruthi) / WHO 2019",
    "diaper": "AAP HealthyChildren — Diapering / 대한소아청소년과학회 일반 가이드 (참고용, 공식 상한 없음)",
    "growth": "WHO Child Growth Standards 2006 (0–24m) L/M/S 백분위"
  }
}
```

### 연령구간별 권장 범위 요약표

| 지표 | 0–3개월 | 4–11개월 | 12–23개월 | 단위 | 출처 |
|---|---|---|---|---|---|
| 수유(분유) | 체중kg×150~180 (상한 960) | 동일 (이유식 병행 시 감소) | 동일 | ml/일 | AAP |
| 총 수면 | 14~17 | 12~16 | 11~14 | h/일 | NSF/AASM/WHO |
| 소변 | 6회+ | 6회+ | 5회+ | 회/일 하한 | AAP |
| 대변 | 3~12 (넓음) | 1~8 | 1~4 | 회/일 참고 | 참고용, 공식 상한 없음 |
| 터미타임 | 5~30 | 30~90 | — | 분/일 | AAP Tummy to Play |
| 성장(체중·키·머리둘레) | WHO 3/15/50/85/97 백분위 밴드 | 동일 | 동일 | 백분위 | WHO 2006 |

### 성장 WHO 밴드 데이터 — `Resources/Guidelines/who_growth_{weight,height,headcirc}_{boy,girl}.json`
```jsonc
// 성별×지표별 파일. 월령 0~24 각 행에 백분위 값(선형보간용).
{ "metric":"weight","sex":"boy","unit":"kg",
  "rows":[ { "m":0, "p3":2.5,"p15":2.9,"p50":3.3,"p85":3.9,"p97":4.4 }, /* m:1..24 */ ] }
```
표시 밴드: p3–p97 옅은 음영 + p15–p85 진한 음영 + p50 파선. 실측 라인이 위를 지나감.

> **의학 면책(데이터에 내장):** 모든 JSON에 `disclaimer`·`source`. 대변엔 "공식 상한 없음" 명시.
> 대변 상태는 항상 참고톤(‘적정/정보’)만, danger 미사용.

---

## B. 비교·코멘트 엔진 (순수 UseCase) — `Domain/UseCases/EvaluateInsightsUseCase.swift`

Foundation only. 입력=아기 나이(+체중) + 오늘/주/월 집계값. 출력=지표별 `MetricInsight`. 테스트 가능.

### 상태 판정 규칙 (경계 완충 반영)
```
status ∈ { .ok(적정), .low(부족), .high(과다), .noData(정보없음) }  // → StatusTone 매핑

수유: recMin=clamp(kg×150,cap), recMax=clamp(kg×180,cap)
      actual < recMin×(1-0.20) → low ; actual > recMax×(1+0.20) → high ; else ok
      체중 없음 → noData("체중 등록 시 AAP 권장과 비교해 드려요")
수면(h): actual < minH → low ; actual > maxH → high ; else ok  (상한 초과는 danger 아닌 info톤)
소변(회): actual < peeMin → low(주의) ; else ok  (상한 없음)
대변(회): poopMin~poopMax 밖 → info(참고) ; 급변(±30%/주) → info 코멘트. danger 금지
터미타임(분): actual ≥ minMin → ok/목표근접 ; else low("조금씩 늘려볼까요")
데이터 부족: 유효일수 < 3 → noData("기록이 더 쌓이면 분석해 드릴게요 📊")
```

### 코멘트 문구 규칙 (웹 문구 이관·부드러운 톤)
- ok: "오늘 수유 720ml — 권장 600~720ml 안이에요 👍" / "권장(14~17시간) 범위 내예요 😴"
- low: "수면이 권장보다 짧아요. 조금 더 재워볼까요?" (지시·완곡, 단정 금지)
- high: "권장보다 많아요. 보통은 괜찮지만 이상이 있으면 소아과 상담을 권장드려요."
- 추세: `ComputeTrendUseCase` 재사용 → "지난주보다 8% 늘었어요" (|Δ|<10% "비슷해요")
- **모든 문구 톤 규칙:** 진단 단정 금지, "권장/참고/살펴보세요/상담을 권장드려요", 이모지 1개 이하, 데이터 부족 시 비교 생략.

### 출력 타입
```
struct MetricInsight { metric, status, tone(StatusTone), headline(값), comment(문구),
                       recommendedRange: ClosedRange<Double>?, actual, source }
```
`StatusTone` 매핑: ok→success, low→warning, high→info, noData→info(회색톤).

---

## C. 분석 대시보드 UI (애플 건강 감성) — `Feature/Dashboard/`

### C-1. 오늘의 분석 섹션 (신규 `TodayInsightsSection`)
- `DSSectionHeader("오늘의 분석")` + 지표별 `InsightRow`(신규 DS): 아이콘·라벨·값 + `DSStatusPill` + 한 줄 코멘트.
- 상단 요약 한 줄: "잘 먹고·잘 자고 있어요 👍" (전 지표 상태 롤업).
- 카드 하단 고정 면책 캡션(`DSDisclaimerCaption` 신규): "참고용이며 진단이 아니에요 · 출처 AAP·WHO".

### C-2. 지표 추세 + 권장 밴드 오버레이
- 수유량/수면시간 추세 차트에 권장구간 음영: **`RangeBandChart` 헬퍼(신규)** = Swift Charts `RectangleMark`/`AreaMark`(recMin…recMax) + 실측 `LineMark`.
- 기존 `MetricDetailView`·`SparklineChart` 에 밴드 레이어만 추가(드릴다운 유지: 요약카드 → 상세).

### C-3. 성장곡선 WHO 밴드
- `GrowthDetailView.swift:74` 예약된 TODO 실현: 성별·지표 선택 → WHO JSON 로드 → `AreaMark`(p3–p97, p15–p85) + `LineMark`(p50 파선) + 실측 라인.
- 코멘트: "약 50th 백분위예요 (또래 평균 수준)". 백분위는 보간 계산, 정밀 진단 아님 명시.

### C-4. 주/월 분석
- `TrendRange` 토글(DSChip) 유지. 각 기간 평균 vs 밴드 비교 코멘트 재생성.

### 디자인시스템 매핑 & 신규 제안 (→ **DS에 먼저 추가**)
| 재사용 | 신규 제안 (COMPONENTS.md 등록 후 사용) |
|---|---|
| DSCard, DSGaugeBar(normalRange), DSStatusPill, DSSectionHeader, DSChip, DSBadge | **InsightRow** — 아이콘+라벨+값+pill+코멘트 한 줄 행 |
| Swift Charts LineMark/AreaMark | **RangeBandChart** — 추세라인+권장밴드 오버레이 헬퍼(Media/Charts) |
|  | **AnalysisCard** — 헤더+차트+코멘트 조합 컨테이너(DSCard 래핑) |
|  | **DSDisclaimerCaption** — 표준 면책 캡션(Feedback), 재사용 |

> `FeedingAdequacyCard`의 하드코딩(450~600) 제거 → `InsightRow` + 가이드 데이터로 대체.

---

## D. MVP 범위 / 개발 순서

**MVP (지금):** 수유·수면·기저귀 상태+코멘트, 수유·수면 권장밴드 오버레이, 성장 WHO 밴드, 면책 캡션.
**후순위:** 정교한 개인화(수유 방식/조산아 보정), 알림/푸시, 터미타임·놀이 세부 코멘트, 다국어 문구.

### 개발 슬라이스 (의존 순서)
1. **데이터** — `pediatric_guidelines.json` + WHO JSON 번들, `PediatricGuidelineRepository`(Data) + Domain 프로토콜.
2. **엔진** — `EvaluateInsightsUseCase` + `MetricInsight`, 유닛테스트(경계 ±20%, noData, cap).
3. **DS 신규** — InsightRow, DSDisclaimerCaption, RangeBandChart, AnalysisCard + COMPONENTS.md 등록.
4. **UI-오늘** — `TodayInsightsSection` 붙이고 `FeedingAdequacyCard` 대체, ViewModel에 인사이트 배선.
5. **UI-추세밴드** — 수유·수면 추세에 RangeBandChart 밴드.
6. **UI-성장** — GrowthDetailView WHO 밴드 + 백분위 코멘트.
7. **문구·면책 QA** — 톤 검수, 출처 표기, 데이터부족 경로.

---

## 의학적 면책 처리 방침
- 출처(AAP·WHO·NSF/AASM·대한소아청소년과학회)를 **데이터(JSON source)와 화면(면책 캡션)** 양쪽에 명시.
- 표준 문구: "참고용이며 의학적 진단이 아니에요. 개인차는 정상이며, 이상이 있으면 소아과 상담을 권장드려요."
- 톤: 단정·경보 금지, 완곡·권유형. 대변은 공식 상한 없음 → 항상 참고톤(danger 미사용).
- 모유수유는 양 측정 곤란 → 수유량 비교에서 제외하고 안내로 대체.
