# 대시보드 달력 디자인 명세서 (Dashboard Calendar Design)

> 상태: v1 · 작성: 프로덕트 디자이너 · 대상 레포: `zzippu_ios` (SwiftUI, 클린5레이어)
> 원본 기획: [`DASHBOARD_CALENDAR_PLAN.md`](./DASHBOARD_CALENDAR_PLAN.md) — 이 문서는 그 기획의 **시각화 명세**다.
> 디자인시스템: `Shared/DesignSystem/Theme/Theme.swift`, `docs/design-system/tokens.json`
> 원칙: **raw 색·매직넘버 금지, theme 토큰만.** 다크모드 필수. 애플 Calendar 월 뷰 레퍼런스.
> 개발 에이전트가 이 문서로 S5(DS 컴포넌트)/S4(섹션)·S6(통합)을 구현한다. 코드 예시는 참고용 표기이며 실제 구현은 개발자 몫.

---

## 0. 설계 요약 (한 눈에)

- **컨테이너**: 대시보드 최상단 `CardContainer(style: .plain)` 1장. 내부에 [월 헤더] → [요일 헤더] → [6주 그리드] → [범례] → [검진 배너] 수직 스택.
- **셀 = 2단 스택**: 상단 날짜 숫자(`caption`/13pt급), 하단 총 수유량 숫자(`label`/12pt mono, tabular). 그 아래 데코 슬롯(도트/언더바)은 절대배치로 얹음.
- **오늘 강조 = 애플식 원형 채움**: `primary` 채운 원 + `onPrimary` 흰 숫자. 미래·넘침칸과 명확히 구분.
- **검진 = 단일 도메인색(신규 토큰 `domainCheckup`)**: 시작일 도트+"N차" 라벨 + 창 하단 언더바(캡슐 끝) + 하단 D-day 배너. 색만 의존 금지 → 항상 도트/라벨/텍스트 병행.
- **신규 토큰 제안 2개**: `semantic.color.domain.checkup.{solid,tint}` (검진 표시 전용 1색), 그리고 셀 레이아웃 상수 묶음 `component.calendarCell.*`. 남발 없이 최소.

---

## 1. 전체 레이아웃

### 1.1 컨테이너 (DSCard 톤)

```
╔══════════════════════════════════════════════╗  ← CardContainer(.plain)
║  ‹      2026년 7월      ›            [오늘]    ║  월 헤더 (h = 44)
║                                                ║
║   일   월   화   수   목   금   토             ║  요일 헤더 (h = 24)
║  ┌──┬──┬──┬──┬──┬──┬──┐                        ║
║  │  │  │ 1│ 2│ 3│ 4│ 5│                        ║  6주 그리드
║  ├──┼──┼──┼──┼──┼──┼──┤                        ║  (셀 minHeight 52)
║  │ 6│ 7│ 8│ 9│10│11│12│                        ║
║   … 6행 …                                      ║
║  └──┴──┴──┴──┴──┴──┴──┘                        ║
║                                                ║
║  숫자 = 하루 총 수유량(ml)  · N차 검진 기간     ║  범례 (caption, textTertiary)
║ ┌────────────────────────────────────────────┐ ║
║ │ 🩺 다가오는 검진: 2차 · D-40 (8/22~11/21)   │ ║  검진 배너 (surfaceSunken 톤)
║ └────────────────────────────────────────────┘ ║
╚══════════════════════════════════════════════╝
```

- 카드 패딩: `theme.component.card.padding` (= `cardPadding` 20). 단, 그리드는 셀이 카드 폭을 꽉 채워야 하므로 **그리드만 좌우 패딩을 20 → 0으로 상쇄**하고 셀 간 내부 간격으로 정렬(1.3 참조). 헤더·범례·배너는 카드 패딩 유지.
- 카드 배경/테두리/그림자: DSCard 기본(`surface` + `cardBorder` + `shadow.sm`). 별도 지정 없음.
- 섹션 내부 수직 리듬: 블록 사이 `theme.space.stackGapMd`(12). 배너 위만 `theme.space.sectionGap`(16)로 살짝 띄움.

### 1.2 월 헤더

| 요소 | 값 | 토큰 |
|------|-----|------|
| 컨테이너 높이 | 44 | `primitive.size.touchMin` (chevron 터치타깃) |
| chevron `‹` `›` | 아이콘 20pt, tint=`textSecondary`, 44×44 히트영역 | `DSIconButton(iconSize: 20, tint: .secondary)` |
| chevron 비활성 | opacity `primitive.opacity.muted`(0.3), 탭 불가 | 하한(생일 월)·상한(8차 end 월) 초과 시 |
| 월 텍스트 `2026년 7월` | `typography.headline`(16/semibold), `textStrong` | 웹 헤더 날짜 톤(`textStrong` = gray-700) |
| "오늘" 액션 | `typography.captionStrong`(12/semibold), `primary`, pill 배경 `primaryTint` paddingX `2_5`(10)/Y `1`(4) | 이번 달이 아닐 때만 노출. `statusPill` 토큰 재사용 |

- 월 텍스트는 헤더 **가운데**, chevron은 좌/우 끝, "오늘"은 우측 chevron 안쪽(또는 헤더 우상단). 이번 달을 보고 있으면 "오늘" 자리 비움(레이아웃 점프 방지 위해 폭 예약).

### 1.3 요일 헤더 & 그리드

- 요일 헤더: `일 월 화 수 목 금 토`, 일요일 시작. `typography.label`(12/medium).
  - 평일: `textSecondary`. **주말**: 일요일 = `status.danger.fg`(rose), 토요일 = `status.info.fg`(blue). (애플 캘린더 관례 근사 — 강한 원색 대신 상태 fg 톤으로 은은하게.)
  - 높이 24, 하단 `theme.space.xs`(4) 여백.
- 그리드: `LazyVGrid` 7열, **6행 고정 42칸**. 열 간격·행 간격 = `theme.space.xs`(4). 셀 폭 = 균등(`.flexible()`). 셀 높이 = `component.calendarCell.minHeight`(52, 신규).
  - 그리드 좌우: 카드 패딩(20)을 상쇄해 카드 가장자리에서 셀까지 여백을 4로. → 셀이 넓어져 3~4자리 수유량 가독성 확보.

---

## 2. 날짜 셀 상세 (가장 중요)

### 2.1 셀 내부 배치

```
┌──────────┐   ← 셀 폭 ~48, minHeight 52
│    12    │   상단: 날짜 숫자 (원형 강조는 이 숫자에만)
│   720    │   하단: 총 수유량 숫자 (mono, tabular, 단위 없음)
│  ·2차 ▔  │   데코 오버레이 (도트+라벨 / 언더바) — 절대배치
└──────────┘
```

- **수직 구조**: `VStack(spacing: 2)` — [날짜 숫자] / [수유량 숫자]. 상단 정렬. 데코(도트·언더바)는 `ZStack`/`overlay`로 이 스택 위에 얹어 **수유량 숫자와 세로로 겹치지 않게** 배치(도트=우상단, 언더바=셀 최하단).
- 셀 내부 패딩: 상 `theme.space.xs`(4), 좌우 2, 하 3(언더바 자리 확보).

### 2.2 날짜 숫자

| 상태 | 색 | 굵기/폰트 | 배경 |
|------|-----|-----------|------|
| 평상(당월·데이터 유무 무관) | `textPrimary` | `caption`(12) regular | 없음 |
| **오늘** | `onPrimary`(흰색) | `captionStrong`(12) semibold | **`primary` 채운 원** ⌀ 24, 숫자 중앙 |
| 미래(당월) | `textSecondary` | `caption` | 없음 (흐리게 X — 검진 가독성 유지, 기획 2절) |
| 넘침칸(이전/다음달) | `textTertiary` | `caption` | 없음. 데코 일절 없음 |
| 주말 숫자 색 보정 | 일=`status.danger.fg` / 토=`status.info.fg`의 **60% 불투명** | — | 요일헤더보다 약하게(숫자는 데이터가 주인공) |

- **오늘 원형**: 애플식 **채움 원** 채택(아웃라인 아님). 이유: 대시보드에서 "오늘"은 가장 강한 앵커여야 하고, 아웃라인은 검진 도트·언더바 색선과 시각적으로 혼동됨. 원 지름 24(`primitive.size.iconLg`), 숫자 중앙.
  - 오늘이면서 데이터가 있으면: 원은 날짜 숫자에만, 수유량 숫자는 원 아래 정상 표기.

### 2.3 총 수유량 숫자

| 항목 | 값 | 토큰 |
|------|-----|------|
| 폰트 | mono, tabular, 12 | `typography.mono` (caption2/12/medium mono) |
| 색(데이터 있음) | `textStrong` | 날짜(textPrimary)보다 약간 물러난 보조 강조. 숫자 인식 O, 위계 유지 |
| 데이터 없음(당월·과거/오늘) | **공란** (0 표기 안 함) | 기획 2절: "기록 없음"과 "0ml" 구분 |
| 미래·넘침칸 | 공란 | — |
| 단위 | **셀엔 없음** | `ml`은 하단 범례에 1회: "숫자 = 하루 총 수유량(ml)" |
| 큰 숫자(3~4자리) | `minimumScaleFactor(0.8)`, `lineLimit(1)` | 셀 폭 초과 방지 |

- **단위 표기 원칙**: 셀엔 순수 숫자만(`720`). 노이즈 방지. 단위는 범례·배너·VoiceOver 라벨에만.

### 2.4 셀 크기·간격 & 큰 글씨(Dynamic Type) 대응

- 셀 minHeight 52 / 셀 간격 4 (2.1, 1.3).
- **큰 글씨 대응(dsTypeCap)**: 셀 내 텍스트(날짜·수유량)는 이미 캡된 스케일(display/mono가 상한 처리)을 쓰되, 추가로 `minimumScaleFactor(0.8)` + `lineLimit(1)`. 접근성 큰 텍스트 사용자는 셀 내부 축약을 감수하고 **배너/범례에서 풀 텍스트로 보완**(기획 6절 R1). 셀 높이는 52 고정(높이 튐 방지) — 텍스트만 축소.
- 셀은 읽기전용이므로 44 터치타깃 불필요(탭 없음). 단 향후 딥링크 대비해 셀 전체를 hit-testable 영역으로 유지 가능.

---

## 3. 영유아 검진 표시 (하이브리드 b + a-lite + c)

검진 = **단일 도메인색**(신규 `domainCheckup`, 6.2 참조). 세 요소가 모두 이 색을 공유해 "검진"으로 묶여 읽힌다. 색만으로 구분하지 않도록 항상 라벨/도트/텍스트 병행.

### 3.1 (b) 시작일 도트 + "N차" 라벨

| 항목 | 값 | 위치 |
|------|-----|------|
| 도트 | ⌀ 6 (`timelineDotSizeIdle`), `domainCheckup.solid` 채움 | 셀 우상단, 날짜 숫자 우측 상단 모서리 |
| "N차" 라벨 | `typography.label`(12→축소 허용), `domainCheckup.solid` | 도트 옆 또는 도트 아래 1줄. 공간 부족 시 도트만 + VoiceOver로 "N차" 전달 |
| 노출 조건 | 검진 창 **start 날짜 칸에만** | 화면에 start 없으면 도트/라벨 없음(정상) |

- 도트·라벨은 **셀 상단(날짜 옆)**에 둬 하단 수유량 숫자와 물리적으로 분리 → 겹침 없음.

### 3.2 (a-lite) 창 언더바

| 항목 | 값 |
|------|-----|
| 형태 | 셀 **최하단**의 얇은 가로 바. 높이 3, 좌우 인셋 3 |
| 색 | `domainCheckup.solid` (라이트) / 다크는 동일 solid (도메인 색은 다크도 채도 유지) |
| span 처리 | `SpanRole`로 끝 처리: `.start`/`.single` = 좌측 끝 캡슐 라운드, `.end`/`.single` = 우측 끝 캡슐 라운드, `.middle` = 사각(연속). 라운드 = 바 높이/2 |
| 배경 채움 | **없음** (기획: 색면 부담 회피). 언더바만 |
| 넘침칸 | 언더바 표시 안 함(당월 데이터만) — 월 경계에서 잘림은 정상 |

### 3.3 (c) 다가오는 검진 D-day 배너

```
┌────────────────────────────────────────────┐
│ 🩺  다가오는 검진: 2차 · D-40  (8/22~11/21)  │
└────────────────────────────────────────────┘
```

| 항목 | 값 | 토큰 |
|------|-----|------|
| 컨테이너 | 카드 하단, 전폭 | `dsCard(style: .sunken)` 또는 `surfaceSunken` 배경 + radius `control`(12) |
| 좌측 도트/아이콘 | ⌀ 8 `domainCheckup.solid` 채움(색맹 대비 아이콘 병행 권장) | `timelineDotSize` |
| 본문 | "다가오는 검진: **N차 · D-day** (M/D~M/D)" | `typography.body`(14/medium), `textPrimary`. "N차·D-day"만 `captionStrong` 강조 |
| 진행 중 | "N차 · 진행 중 (마감까지 D-12)" | 동일 스타일 |
| 예정 없음(8차 이후) | 배너 숨김 또는 "예정된 검진 없음" `textTertiary` | 기획 6절 |
| paddingX/Y | `componentPaddingX`(16) / `stackGapSm`(8) | — |

### 3.4 검진 범례

- 범례 줄에 "● N차 검진 기간" 1항 추가. 도트 = `domainCheckup.solid`. `typography.caption`, `textTertiary`.
- 전체 범례: `숫자 = 하루 총 수유량(ml)` · `● N차 검진 기간` (가운뎃점/여백으로 구분).

---

## 4. 확장 데코레이션 슬롯 (겹침·우선순위 규칙)

기획 4절의 `CalendarDecorationSlot`(primaryValue / eventBadge / underbar / footnote)을 **셀 내 물리적 위치**로 고정 매핑한다. 한 셀에 여러 레이어가 겹쳐도 슬롯이 분리돼 충돌하지 않는다.

| 슬롯 | 셀 내 위치 | 현재 사용 | z 우선순위 | 최대 표기 |
|------|-----------|-----------|-----------|-----------|
| `eventBadge` | 우상단 모서리 | 검진 도트+"N차" | 최상 (3) | 도트 **1개**. 2개↑면 `+N` |
| `primaryValue` | 셀 중앙 하단(날짜 아래) | 수유량 숫자 | 기준 (0) | 텍스트 1줄 |
| `underbar` | 셀 최하단 가로선 | 검진 창 구간 | 배경 위(1) | 바 **1겹**. 2개 겹치면 2px씩 위로 쌓되 최대 2겹 |
| `footnote` | 좌하단(예약, 미래) | (미사용) | 배경 위(1) | 미래 데코용 슬롯 |

### 4.1 오버플로우 규칙 ("+N")

- **eventBadge 2개 이상**(같은 날 검진+예방접종 등 미래): 첫 배지만 도트로 표기, 나머지는 **`+N`** 라벨(`typography.label`, `textSecondary`)을 도트 옆에. VoiceOver는 전부 나열.
- **underbar 2겹 초과**: 최대 2겹만 그리고, 그 이상은 그리지 않음(색선 과밀 방지). 배너/VoiceOver로 보완.
- **primaryValue 슬롯 충돌**(미래 "수면 총량"이 같은 슬롯 요구): 동시 표시 불가 → **표시 모드 토글**(수유량/수면 택1, 헤더에 세그먼트). 슬롯 enum이 충돌을 드러내므로 설계 시 결정(기획 R4).

### 4.2 kind → theme 색 매핑 (DS는 Domain 비의존)

View가 `CalendarDecorationKind`를 theme 토큰으로 매핑. DS 컴포넌트는 색 없는 DTO(해석된 `Color`)만 받는다(기존 `DSDonutSegment`/`TimelineItemRow.dotColor` 패턴).

| kind | 색 토큰 |
|------|---------|
| `feedingVolume` | `textStrong` (숫자 텍스트색) |
| `checkupWindow` | **`domainCheckup.solid`** (신규) |
| (미래) `sleepTotal` | `domainSleepSolid` |
| (미래) `vaccination` | 별도 도메인색 or `status.info.solid`(검진과 구분되는 색) |

---

## 5. 상태 (로딩·빈 달·경계·다크)

| 상태 | 디자인 |
|------|--------|
| **로딩(스켈레톤)** | 42칸 그리드 유지, 셀마다 수유량 자리에 `surfaceSunken` 라운드 바(폭 60%, 높이 8, radius `sm`) shimmer. 날짜 숫자는 즉시 렌더(순수 계산). 헤더·요일은 실제. 배너 자리엔 sunken 바 1줄 |
| **빈 달(기록 전무)** | 그리드·검진 정상, 수유량 전부 공란. 카드 하단 미세 안내(옵션) "이 달 수유 기록 없음" `emptyState` 토큰(`textTertiary`/caption) |
| **생일 이전 달** | 이전 chevron 비활성(0.3). 생일 이전 날짜 칸 = 넘침칸처럼 무데코(수유량·검진 없음), 숫자만 `textTertiary` |
| **검진 종료(8차 end 이후)** | 검진 데코 없음(정상). 배너 = "예정된 검진 없음" 또는 숨김 |
| **다크모드** | 아래 대비값 표 |

### 5.1 다크모드 대비값 (모두 토큰이 자동 처리 — 확인용)

| 요소 | 라이트 | 다크 |
|------|--------|------|
| 카드 배경 | white | gray-800 (`surface`) |
| 카드 테두리 | 투명(그림자) | gray-700 (`cardBorder`) |
| 날짜 숫자 | gray-900 | gray-50 (`textPrimary`) |
| 수유량 숫자 | gray-700 | gray-300 (`textStrong`) |
| 넘침칸 숫자 | gray-400 | gray-500 (`textTertiary`) |
| 오늘 원 | blue-400 채움/흰 숫자 | blue-500 채움/흰 숫자 (`primary`/`onPrimary`) |
| 검진 색(도트·바·배너) | `domainCheckup.solid` light | `domainCheckup.solid` dark(채도 유지, 6.2) |
| 스켈레톤 | gray-100 | gray-700 (`surfaceSunken`) |

---

## 6. 토큰 매핑 표 & 신규 토큰 제안

### 6.1 사용 토큰 (기존)

| 항목 | theme 경로 |
|------|-----------|
| 카드 배경/테두리/그림자/패딩/라운드 | `component.card.*` |
| 월 텍스트 색 | `color.textStrong` |
| 월 텍스트 폰트 | `typography.headline` |
| chevron tint | `color.textSecondary` / 비활성 `opacity.muted`(0.3) |
| "오늘" pill | `color.primaryTint` bg, `color.primary` fg, `typography.captionStrong`, `component.statusPill.paddingX/Y` |
| 요일 평일 | `color.textSecondary`, `typography.label` |
| 요일 일/토 | `color.statusDangerFg` / `color.statusInfoFg` |
| 날짜 숫자(평상) | `color.textPrimary`, `typography.caption` |
| 날짜 숫자(미래) | `color.textSecondary` |
| 날짜 숫자(넘침) | `color.textTertiary` |
| 오늘 원 | `color.primary` 채움 / `color.onPrimary` 숫자, ⌀ `size.iconLg`(24) |
| 수유량 숫자 | `typography.mono`, `color.textStrong` |
| 검진 배너 배경 | `color.surfaceSunken`, radius `radius.control` |
| 검진 배너 본문 | `typography.body` / 강조 `typography.captionStrong`, `color.textPrimary` |
| 검진 도트(배너) | ⌀ `component.timelineDotSize`(10) |
| 검진 도트(셀) | ⌀ `component.timelineDotSizeIdle`(8→6 사용) |
| 그리드/셀 간격 | `space.xs`(4) |
| 범례 | `typography.caption`, `color.textTertiary` |
| 빈 달 안내 | `component.emptyState.*` |

### 6.2 신규 토큰 제안 (최소 2건)

**(A) 검진 도메인색 — `semantic.color.domain.checkup`** (필수, 신규 도메인이므로 정당)

기존 domain 팔레트에 검진 kind가 없다. 검진은 수유(blue)·수면(purple)·기저귀와 **구분되는 1색**이어야 한다. **teal 계열**을 제안(의료/검진 뉘앙스, 기존 도메인색과 충돌 없음). 없으면 `status.info`(blue) 재사용도 가능하나 수유(blue)와 혼동되므로 신규 권장.

```jsonc
// tokens.json → semantic.color.domain 에 추가
"checkup": {
  "$comment": "영유아 검진 표시 전용 도메인색(달력 도트/언더바/배너). 수유(blue)·수면(purple)과 구분되는 teal.",
  "solid": { "value": { "light": "{primitive.color.teal.500}", "dark": "{primitive.color.teal.400}" } },
  "tint":  { "value": { "light": "{primitive.color.teal.50}",  "dark": "rgba(20,184,166,0.22)" } }
}
```
- primitive에 `teal`이 없으므로 승격 필요: `teal.50 #F0FDFA`, `teal.400 #2DD4BF`, `teal.500 #14B8A6`. (teal 도입이 부담되면 대안: `emerald`(이미 존재) 재사용 → `domainCheckup.solid = emerald.600/400`. 단 emerald는 게이지 "적정"에 이미 쓰이므로 의미 충돌 소지 → teal 우선 권장.)
- Theme.swift 매핑: `ThemeColor`에 `domainCheckupSolid` / `domainCheckupTint` 추가, `DomainKind`에 `.checkup` 케이스 + `solid(for:)`/`tint(for:)` 분기 추가.

**(B) 셀 레이아웃 상수 — `component.calendarCell`** (권장, 매직넘버 방지)

```jsonc
// tokens.json → component 에 추가
"calendarCell": {
  "$comment": "달력 날짜 셀. 읽기전용이라 44 불필요, 6주 고정 높이.",
  "minHeight":     { "value": 52 },
  "spacing":       { "value": "{primitive.space.1}" },      // 4 (셀 간격)
  "todayCircle":   { "value": "{primitive.size.iconLg}" },  // 24
  "underbarHeight":{ "value": 3 },
  "eventDotSize":  { "value": 6 }
}
```
- 남발 방지 위해 상수는 이 묶음 하나로 응집. `Theme.swift`에 `ComponentCalendarCellTokens` struct 추가.

---

## 7. 접근성

- **색만으로 구분 금지**: 검진은 항상 (도트 + "N차" 라벨 + 언더바 + 배너 텍스트)를 병행. 색맹 사용자도 라벨/텍스트로 인지. 주말도 색+위치(고정 열)로 이중.
- **대비**: 오늘 원 = `primary` 위 `onPrimary`(흰색) → 대비 확보. 수유량 `textStrong`(gray-700/300)은 배경 대비 AA 충족. 넘침칸 `textTertiary`는 의도적 저대비지만 "당월 아님"이 유일 정보라 허용(핵심 정보 아님).
- **큰 글씨**: 셀은 축약(`minimumScaleFactor` 0.8) + 배너/범례 풀 텍스트 보완.
- **VoiceOver 라벨 예시** (셀 하나를 `accessibilityElement(children: .ignore)`로 묶고 label 합성):

| 상황 | accessibilityLabel |
|------|--------------------|
| 데이터+검진 시작일+오늘 | "7월 12일, 오늘. 총 수유 720밀리리터. 2차 검진 시작일." |
| 데이터만 | "7월 8일. 총 수유 650밀리리터." |
| 기록 없음 | "7월 3일. 수유 기록 없음." |
| 미래·검진 기간 중 | "8월 25일. 2차 검진 기간." |
| 넘침칸 | "6월 30일. 이번 달 아님." (또는 `.isHidden`으로 스킵) |
| 배너 | "다가오는 검진. 2차. 40일 남음. 기간 8월 22일부터 11월 21일." |

- chevron: label "이전 달"/"다음 달", 비활성 시 `.accessibilityHidden` 또는 disabled 트레잇. "오늘" 버튼: "오늘로 이동".
- `accessibilityHint` (셀): 읽기전용이므로 힌트 없음(향후 딥링크 시 "탭하여 상세 보기" 추가).

---

## 8. ASCII 목업 — 상세 셀 3종

```
평상(데이터 있음)      오늘(데이터+검진 시작)     검진 기간 중(미래)
┌────────┐            ┌────────┐                ┌────────┐
│  8     │            │ (12)·2차│  ← 원+우상단   │  25    │
│  650   │            │  720   │     도트+라벨   │        │  ← 미래=공란
│        │            │        │                │  ▔▔▔▔  │  ← 언더바(middle)
└────────┘            └────────┘                └────────┘
 숫자 textStrong       (12)=primary 원          언더바 domainCheckup
                       720=수유량 정상

넘침칸(다음달)        검진 시작일(캡슐 좌끝)     로딩 스켈레톤
┌────────┐            ┌────────┐                ┌────────┐
│  1     │  ← 흐림    │  22 ·2차│               │  9     │
│        │  textTert  │        │                │ ▂▂▂▂   │  ← shimmer bar
│        │  데코 없음 │  ▕▔▔▔  │  ← 좌끝 라운드 │        │
└────────┘            └────────┘                └────────┘
```

---

## 9. 개발 체크리스트 (S5 DS 컴포넌트 관점)

- [ ] `CalendarCellView`: 색 없는 DTO 수신 (dateNumber, volumeText?, isToday, isOutside, isFuture, eventBadge?(dotColor,label), underbar?(color,spanRole)).
- [ ] `WeekdayHeaderView`: 7칸, 주말 색 분기.
- [ ] `MonthHeaderView`: chevron enabled 플래그 2개 + onToday?.
- [ ] `CheckupBannerView`: (dotColor, primaryText, dateRangeText).
- [ ] 신규 토큰 A(`domainCheckup`) + B(`calendarCell`) 반영: `tokens.json` → `Theme.swift`(`ThemeColor`/`DomainKind`/`ComponentCalendarCellTokens`) → `.zzippu` 인스턴스.
- [ ] 다크/Dynamic Type/VoiceOver 프리뷰 3종.
- [ ] raw 색·매직넘버 0건 (모두 theme 경유) — 리뷰 게이트.
```
