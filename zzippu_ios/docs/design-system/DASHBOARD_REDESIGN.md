# 대시보드 재설계 — 애플 건강앱 감성 (먹놀잠 / 찌뿌둥, iOS SwiftUI)

> 목적: 신생아 부모가 **"오늘 잘 크고 있나"를 한눈에** 파악. 애플 건강(Health)앱식 정보 위계 — 깔끔한 요약 카드, 절제된 타이포, 미니 그래프 → 상세 드릴다운, 도넛·링·막대로 가시성 확보.
> 원칙: 클린아키텍처(집계=UseCase, UI=Feature+DS), theme/DS 토큰만 사용(raw 색 금지), 의학 인사이트는 완곡·면책 유지, web-parity 타이포(body 14 / display 36 한정) 준수.
> 코드 금지 — 설계 사양서. 개발은 §7 슬라이스 순서대로.

---

## 0. 현재 진단 (근거)

수집한 현행 코드에서 확인된 문제:

| 위치 | 현상 | 판정 |
|---|---|---|
| `DashboardSummaryCards.swift` `NextFeedingCard` | 다음 수유 시각을 `theme.typography.display`(**36pt bold**)로 표기 | **과대** (사용자 피드백 핵심). 웹은 동일 정보를 `text-sm font-bold`(인라인)로 처리 |
| `MetricCard.swift` | 카드 4장 각각 값을 `display`(36pt)로 표기 → 화면에 **36pt 숫자 5~6개** 동시 노출 | **과대** (위계 붕괴, "다 큰 글씨") |
| `FeedingAdequacyCard.swift` | 총 수유량 `display`(36pt) — 이건 화면 대표 지표라 **유지 후보** | 유지(단, 화면당 1개 원칙) |
| `GrowthMetricCard` | 체중·키 각각 `display`(36pt) 2개 | **과대** (한 카드에 36pt 2개) |
| 수유량 시각화 | 카드=막대 스파크라인만, **분유/모유 비중(도넛) 없음** | **부족** (피드백: "원/막대로 가시성") |
| 기저귀 시각화 | 막대 스파크라인만, **소/대 비중 없음** | **부족** |
| 수유 적정 | `DSGaugeBar`(가로 막대) 사용 중 | 양호 → 카드 그리드엔 **미니 링**으로 승격 제안 |
| 추세 | 상세뷰에 기간토글(`RangePicker`)+`ComputeTrendUseCase` 이미 있음 | **양호** (재배치·강화만) |

**핵심 처방**: display(36pt)를 **화면당 1~2개**로 제한. "다음 수유"는 시각을 `title`(18)로 축소. 카드 값은 `title/headline`(18/16). 수유량·기저귀에 **도넛**, 수유 적정에 **링**, 수면에 **구간 막대** 추가.

---

## 1. 화면 구조 (위 → 아래)

애플 건강앱 "요약" 탭의 위계를 차용: 상단 하이라이트 → 대표 지표 1개 강조 → 카드 그리드(미니 그래프+상태) → 예측 → 성장 → (탭 시) 상세.

```
┌─────────────────────────────────────────┐
│ NavigationTitle "대시보드" (large)         │
│                                           │
│ ① 오늘의 하이라이트  ← AnalysisCard(오늘의 분석) │  롤업 한 줄 + InsightRow 목록
│    "대체로 좋아요 · 수면을 살펴볼까요?"        │  (기존 TodayInsightsSection 유지)
│                                           │
│ ② 오늘 수유량 (대표 지표, 화면 유일 display36) │  큰 숫자 1개 + 링/게이지 + 상태 pill
│    ◖ 380 ml ◗   [적정]                     │  (FeedingAdequacyCard 리네이밍·유지)
│    권장 525~630ml · AAP                     │
│                                           │
│ ─ "오늘 요약" (DSSectionHeader) ─────────   │
│ ③ 2열 지표 카드 그리드                        │  각 카드: 미니 그래프 + 값(title18) + 상태
│   ┌──────────┐ ┌──────────┐              │
│   │ 🍼 수유   │ │ 😴 수면   │              │  수유=미니도넛, 수면=구간막대
│   │  ◐ 680ml │ │ ▓▓░ 14h  │              │
│   │  분유:모유 │ │ 낮잠3 밤1 │              │
│   ├──────────┤ ├──────────┤              │
│   │ 🧷 기저귀 │ │ 🤸 놀이   │              │  기저귀=소대도넛, 놀이=막대
│   │  ◑ 8회   │ │ ▁▃▅ 45분 │              │
│   │  소5 대3  │ │ 터미15분  │              │
│   └──────────┘ └──────────┘              │
│                                           │
│ ④ 다음 수유 예상 (적정 크기)                  │  아이콘 + 시각 title18 + "약 40분 후"
│    🕐 다음 수유 예상  15:20  · 약 40분 후     │  (NextFeedingCard 축소)
│    🌙 다음 수면 예상  16:10                   │
│                                           │
│ ⑤ 성장 요약 (전폭 카드)                       │  체중·키 headline16 + WHO 미니밴드
│    📈 성장   4.2kg · 55.0cm   [p50]         │
│                                           │
└─────────────────────────────────────────┘
  각 카드 탭 → 상세뷰 push (기간 세그먼트 + 큰 차트 + 추세 인사이트)
```

**위계 규칙** (건강앱 감성):
- 화면 최상단 = **분석 롤업**(무슨 일이 있나 한 줄) → 그 다음 **대표 수치 1개**(수유량) → 나머지는 **동등한 카드 그리드**.
- 예측(④)은 "행동 유도" 정보라 그리드 아래로 내림. 현재는 최상단인데 과대 강조라 위치·크기 모두 하향.
- 여백: `sectionGap`(섹션 간), 카드 내부 `padding(16)`, 그리드 간격 12 유지.

---

## 2. 카드별 그래프 지정

| # | 카드 | 그래프 | 데이터 소스 | 컴포넌트 |
|---|---|---|---|---|
| ① | 오늘의 분석 | (그래프 없음, 상태 pill 목록) | `vm.insights` (EvaluateInsightsUseCase) | `AnalysisCard`+`InsightRow` (기존) |
| ② | 오늘 수유량 | **링(Ring) or 가로 게이지** — 권장 밴드 대비 채움 | `dailySummary.totalFeedingMl`, `feedingRecommendedRange` | **신규 `DSRingGauge`** (권장) 또는 기존 `DSGaugeBar` |
| ③-a | 수유 카드 | **미니 도넛** — 분유 vs 모유 비중 | 신규 집계: 분유 ml : 모유 회수/분 | **신규 `DSDonutChart`** |
| ③-b | 수면 카드 | **구간 막대(스택)** — 낮잠/밤잠 or 7일 미니막대 | `sleepSparkPoints` / 낮밤 분리 집계 | 기존 `SparklineChart(.bar)` 강화 or `DSSegmentBar` |
| ③-c | 기저귀 카드 | **미니 도넛** — 소(pee) vs 대(poop) 비중 | `dailySummary.peeCount`, `poopCount` | **신규 `DSDonutChart`** |
| ③-d | 놀이 카드 | **미니 막대** — 7일 놀이 시간 | `playSparkPoints` | 기존 `SparklineChart(.bar)` |
| ⑤ | 성장 카드 | **WHO 미니밴드 라인** (축 숨김) | `growthSeries` + WHO 백분위 | 기존 `RangeBandChart(showAxes:false)` |
| 상세 | 수유 상세 | 일별 **막대** + 권장밴드 + 평균선 | `ComputeTrendUseCase.feedingTrend` | Swift Charts `BarMark`+`RectangleMark`(기존) |
| 상세 | 수면 상세 | **에어리어 라인** + 권장밴드 | `sleepTrend` | Swift Charts `AreaMark`+`LineMark`(기존) |
| 상세 | 기저귀 상세 | **스택 막대**(소/대) + 평균선 | `diaperTrend` (소/대 분리 확장) | Swift Charts `BarMark`(스택) |
| 상세 | 놀이 상세 | 막대 + 평균선 | `playTrend` | 기존 |
| 상세 | 성장 상세 | WHO 밴드 라인(p3–p97) | `growthSeries` | `RangeBandChart`(기존, `GrowthDetailView`) |

**차트 색상**: 전부 `theme.color.domain*Solid`/`status*` 토큰. 도넛 세그먼트 예 — 수유: 분유=`domainFeedingFormulaSolid`, 모유=`domainFeedingBreastBothSolid`; 기저귀: 소=`domainDiaperPeeSolid`, 대=`domainDiaperPoopSolid`.

**도넛 vs 막대 판단**: "비중(A:B 구성비)"이면 도넛(수유 분유/모유, 기저귀 소/대), "시계열 추이"면 막대·라인(놀이·수면 7일, 상세 추세). 피드백의 "원 그래프"는 비중 카드에, "막대 그래프"는 추이에 배치.

---

## 3. 타이포 / 크기 규율 (web-parity 준수)

토큰(`Typography.generated.swift`): `display 36` / `title 18` / `headline 16` / `body 14` / `caption 12` / `captionStrong 12` / `label 12`.

### 규칙
1. **`display`(36pt)는 화면당 1개** — 대표 지표 **② 오늘 수유량**의 총 ml **하나만**. (성장 상세뷰 등 하위 화면에서 각 1개 허용.)
2. **카드 그리드(③)의 값** = `title`(18, semibold). subValue/라벨 = `caption`(12). → 현재 `display`(36) 사용을 **title로 강등**.
3. **성장 카드(⑤)** 체중·키 = `headline`(16). 라벨 = `caption`. → 현재 `display` 2개를 headline로.
4. **라벨·단위·보조** = `caption`(12) / `captionStrong`(12, 강조 시).
5. Dynamic Type: `display`엔 `dsDynamicTypeCap`(≤xxLarge), 전역 `dsTypeCap`(≤xLarge) 유지.

### ④ "다음 수유" 크기 구체 지정 (과대 해소)
현재: 시각 = `display`(36pt). **→ 변경**:

| 요소 | 현재 | 변경 후 |
|---|---|---|
| 레이블 "다음 수유 예상" | caption 12 | `caption`(12) 유지 |
| **예상 시각 "15:20"** | **display 36** | **`title`(18, semibold)** — 인라인 강조 |
| "약 40분 후 · 평소 3시간 간격" | caption 12 | `caption`(12) 유지 |
| 상태 pill "예측" | — | `DSStatusPill(.info)` 유지 |
| 지남(overdue) 상태 | 없음 | 웹처럼 pill 톤 `.warning` + "수유 시간이에요" (선택) |

→ 웹 `NextFeedingCard`(`text-sm font-bold` 인라인)와 정합. 카드 높이도 48pt 아이콘 → **36pt**로 축소해 밀도 상향. "다음 수면 예상"을 같은 카드에 caption 한 줄로 병합(웹 동일).

---

## 4. 추세(Trends) 통합

추세는 **상세뷰(드릴다운)에 집중** — 요약 화면은 미니 그래프로만 암시, 탭하면 전체 추세.

### 상세뷰 레이아웃 (기존 `MetricDetailView` 강화)
```
┌ [일] [주] [월]  ← RangePicker (DSChip 세그먼트, 기존 TrendRange 확장)
│
│ ┌─────────────────────────────┐
│ │ 수유량 추이 (ml)              │  ← 큰 차트 220h (기존)
│ │  권장밴드 음영 + 막대 + 평균선  │
│ │  ▓▓▓░▓▓▓  ---- 평균 520ml    │
│ └─────────────────────────────┘
│
│ ┌ 추세 배지 ────────────────┐   ← 신규: 웹 TrendInsightCard의 방향 배지 이식
│ │ ↑ 12%  이번 주 vs 지난 주   │      (상승/하강/안정 + %, upIsGood 색)
│ └───────────────────────────┘
│
│ ┌ TrendInsightCard ─────────┐   ← 기존: 완곡 인사이트 + 톤 pill
│ │ [양호] 최근 평균 520ml…      │
│ └───────────────────────────┘
```

**추세 통합 항목**:
1. **기간 세그먼트**: 현재 `TrendRange`(주/월 등). 웹은 7/14일 토글 → iOS도 **일/주/월** 유지하되 `ComputeTrendUseCase`가 anchorDate 기준 집계(이미 지원).
2. **방향 배지 이식**: 웹 `TrendInsightCard`의 `TrendBadge`(↑12% / ↓ / — 안정, `upIsGood`로 녹/적 판단) 개념을 iOS **신규 `DSTrendBadge`**로 추가. `ComputeTrendUseCase`에 "이번 구간 vs 이전 구간 평균 비교"(`calcTrend` 대응) 산출 추가 필요 — **UseCase 확장**(집계는 Domain).
3. **인사이트 배치**: 차트 아래 → 방향 배지 → 완곡 인사이트 카드 순. 면책은 `AnalysisCard`/`DSDisclaimerCaption` 유지.
4. **요약↔상세 일관성**: 요약 카드 미니 그래프의 range는 `.week` 고정(기존), 상세는 토글.

---

## 5. 신규 DS 컴포넌트 제안 ("DS에 먼저 추가")

기존 `COMPONENTS.md` §13(GaugeBar) 옆에 신설. 전부 theme 토큰만, Domain 비의존, `showAxes`/`size` 파라미터로 카드·상세 재사용.

| 컴포넌트 | 용도 | API 스케치(개념) | 재사용 |
|---|---|---|---|
| **`DSDonutChart`** | 비중(2~4 세그먼트) — 수유 분유/모유, 기저귀 소/대 | `segments: [(value, color, label)]`, `centerText:`, `size:` | 카드 미니(size sm, 라벨 숨김) + 상세(size lg, 범례) |
| **`DSRingGauge`** | 단일 진행/적정도 링 — 수유 적정량 | `ratio:`, `normalRange:`, `tone:`, `centerText:` | ② 대표 지표(링형 대안), 카드 미니 |
| **`DSTrendBadge`** | 추세 방향 배지 | `direction: up/down/stable`, `label:`(%), `upIsGood:` | 상세뷰, (선택) 카드 |
| **`DSStatTile`** | 그리드 셀 표준 레이아웃 | `icon/title/value(title18)/sub/graph슬롯/tone` | 그리드 4카드 통일(MetricCard 대체 or 리팩터) |
| **`DSSegmentBar`** (선택) | 스택 구간 막대 — 낮잠/밤잠, 소/대 | `segments:`, `height:` | 수면 카드, 기저귀 상세 |

- `DSDonutChart`/`DSRingGauge`는 Swift Charts `SectorMark`(iOS17+) 또는 `Path` 아크로 구현. 색=`domain*Solid`/`status*` 주입.
- **먼저 DS에 추가** → 그 다음 Feature에서 조립. (COMPONENTS.md에 variant/토큰/웹매핑 행 추가.)
- 도입 안 하는 최소안: `DSGaugeBar`(기존)로 ②·③-a 대체하고 도넛만 신규 추가. 우선순위는 §7.

---

## 6. 현재 대비 변경 (유지 / 축소 / 추가 / 제거)

### 유지
- `TodayInsightsSection`(오늘의 분석) — 위치만 최상단 확정.
- `FeedingAdequacyCard` — 대표 지표(②). display36 **1개만** 여기 허용. 링 대안 검토.
- `MetricDetailView` 4종 상세 차트 + 권장밴드 + `RangePicker` + `TrendInsightCard` — 방향 배지 추가.
- `GrowthDetailView`(WHO 밴드), `RangeBandChart`, `DSGaugeBar`, `SparklineChart`.
- `ComputeTrendUseCase` / `EvaluateInsightsUseCase` — 집계 로직 재사용(추세 방향만 확장).

### 축소 (과대 해소)
- **`NextFeedingCard`**: 시각 display36 → **title18**, 아이콘 48→36, "다음 수면" 한 줄 병합, 위치 최상단 → ④(예측 섹션).
- **`MetricCard`**: 값 display36 → **title18**(그리드 밀도·위계 확보).
- **`GrowthMetricCard`**: 체중·키 display36×2 → **headline16**.

### 추가
- ②/③-a 수유량 → 도넛(분유/모유) 또는 링. ③-c 기저귀 → 소/대 도넛.
- 수면 카드 → 구간/미니막대 강화. 성장 카드 → WHO 미니밴드.
- 상세뷰 → `DSTrendBadge`(방향·%). 신규 DS 컴포넌트(§5).
- VM/UseCase: 분유·모유 ml 분리 집계, 소·대 카운트(이미 있음: peeCount/poopCount), 추세 방향(이전 구간 대비).

### 제거
- 없음(파괴적 제거 없음). `MetricCard`를 `DSStatTile`로 리팩터 시 구파일 대체(동작 동일). 스파크라인은 도넛/막대로 카드별 교체하되 컴포넌트 자체는 존치.

---

## 7. 개발 슬라이스 순서

작은 → 검증가능 → 결합도 낮은 순. 각 슬라이스는 독립 PR 가능.

1. **S1 · 타이포 축소(무위험, 즉효)**
   - `NextFeedingCard` 시각 display→title, 아이콘 축소, "다음 수면" 병합.
   - `MetricCard` 값 display→title, `GrowthMetricCard` display→headline.
   - → 피드백 "글자 크다" 즉시 해소. 신규 컴포넌트 불필요.

2. **S2 · 화면 재배치**
   - `DashboardContentView` 순서: 분석 → 수유량 대표 → 그리드 → 예측 → 성장.
   - `FeedingAdequacyCard` 헤더 "오늘 수유량"으로 통일(웹 정합).

3. **S3 · DSDonutChart 추가 + 수유/기저귀 카드 적용**
   - DS에 `DSDonutChart` 신설(+COMPONENTS.md 행). 
   - VM: 분유/모유 ml, 소/대 카운트 세그먼트 제공.
   - 수유·기저귀 카드 스파크라인 → 도넛.

4. **S4 · DSRingGauge (선택) + 수유량 대표 지표 링화**
   - ② 게이지 → 링 대안(원하면). 미도입 시 `DSGaugeBar` 유지.

5. **S5 · 추세 방향 배지**
   - `ComputeTrendUseCase`에 구간 비교(이번 vs 이전 평균, % · 방향) 추가.
   - `DSTrendBadge` 신설 → 각 상세뷰 차트 상단 배치.

6. **S6 · 수면/성장 카드 그래프 강화**
   - 수면 카드 구간막대(`DSSegmentBar` or 스택), 성장 카드 WHO 미니밴드(`RangeBandChart showAxes:false`).

7. **S7 · DSStatTile 리팩터(정리)**
   - 4 카드 레이아웃을 `DSStatTile`로 통일(그래프 슬롯). 위 슬라이스 안정화 후.

권장 착수: **S1**(피드백 직접 해결) → **S3**(가시성 도넛) → **S2/S5** 순.

---

## 부록 · 데이터 계약 (UseCase 확장 목록)

집계는 전부 UseCase/VM(Domain·Feature), UI는 값만 받음:
- 수유 도넛: `formulaMl : breastMl(or 회수)` — `feedingRepository` 집계 신규(수유타입별 합산).
- 기저귀 도넛: `peeCount : poopCount` — 이미 `dailySummary`에 존재, 매핑만.
- 수면 구간: 낮잠/밤잠 분리(시간대 기준) 또는 7일 `sleepSparkPoints`(기존) 사용.
- 추세 방향: `ComputeTrendUseCase`에 `trendDirection(current, previous) -> (dir, pct)` 추가(웹 `calcTrend` 대응).
- 성장 WHO: `growthSeries` + 백분위 밴드(기존 `GrowthViewModel`/`RangeBandChart` 재사용).

의학 문구: 전부 완곡 + `DSDisclaimerCaption`(AAP·WHO·NSF/AASM 출처, "진단 아님") 유지.
