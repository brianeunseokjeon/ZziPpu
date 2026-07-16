# 편집/입력 바텀시트 UX 개선 스펙 (EDIT_SHEET_REDESIGN)

작성: 기획/디자인 · 대상: 후속 구현(Sonnet) · 코드 변경 없음(스펙 문서)

## 0. 문제 요약 (사용자 원문 취지)

1. **섹션 간격이 과함** → 양/질감/대변색 사이가 `space.lg(24)`라 콘텐츠가 길어지고, 그 결과 **저장·삭제 버튼이 화면 밖으로 밀려** `.medium` detent에서 한 번 더 위로 드래그해야 보임. → **간격 축소 + 한 화면에 다 보이게**.
2. **칩이 글자폭대로** 배치됨(`HStack(spacing: sm)` + `DSChip`). → **행을 균등폭으로 꽉 채우기**(양쪽 바깥은 화면패딩, 칩 사이만 간격). 양/질감/대변색 모두 동일.
3. **저장/삭제 버튼이 홈 인디케이터(세이프에어리어)에 걸려** 터치가 잘 안 됨. → **하단 여백을 safe area 고려해 조절**.

## 1. 확인된 현재 값 (theme 토큰 실측)

| 토큰 | 값(pt) | 비고 |
|---|---|---|
| `space.xs` | 4 | |
| `space.sm` | 8 | 현재 칩 사이 간격 |
| `space.md` | 16 | |
| `space.lg` | 24 | **현재 섹션 세로 간격 (과함)** |
| `space.stackGapMd` | 12 | 헤더-콘텐츠 간격에 재사용 가능 |
| `space.screenPaddingX` | 16 | RecordEditSheet 좌우 패딩 |
| `space.cardPadding` | 20 | DSBottomSheet 내부 좌우/하단 패딩 |
| `component.chip.height` | 44 | 칩 높이(터치 타깃 확보) |
| `component.chip.paddingX` | 14 (`space3_5`) | 칩 좌우 내부 패딩 |
| `component.chip.radius` | (pill/capsule) | `DSChip`은 `Capsule()` |
| `radius.control` | 12 | |
| `radius.controlLg` | 16 | |
| `typography.captionStrong` | 12pt semibold | 칩 라벨 폰트 |
| `typography.caption` | 12pt regular | 섹션 헤더(양/질감/대변색) |

**주의(중복 패딩)**: `DSBottomSheet`는 콘텐츠를 이미 `ScrollView` + 좌우 `cardPadding(20)`으로 감싼다. 그런데 `RecordEditSheet`/`DiaperInputSheet`는 **자체 `VStack{ScrollView{...}}` 구조**로 시트를 채우므로(상단이 콘텐츠 루트) 시트 컨테이너의 좌우 패딩과 **자체 `screenPaddingX(16)`가 이중 적용**될 수 있다. 구현 시 실제 렌더에서 좌우 패딩이 20+16=36으로 과해지는지 확인하고, **자체 시트는 `screenPaddingX(16)` 단일 기준**으로 통일할 것(세그먼트 균등폭 계산이 좌우 패딩에 민감함).

---

## 2. 신규 DS 컴포넌트: `DSSegmentedChips`

위치: `zzippu/Shared/DesignSystem/Components/Inputs/DSSegmentedChips.swift`
(기존 `DSChip.swift` 옆. `DSChip`을 내부에서 재사용해 톤 일치.)

### 2.1 목적
한 행을 **균등폭(`.frame(maxWidth: .infinity)`)** 으로 꽉 채우는 단일선택 세그먼트. 좌우 바깥 여백은 호출부의 화면패딩이 담당하고, 컴포넌트는 **칩 사이 간격만** 책임진다. 선택/비선택 시각은 `DSChip .selectable` 톤을 그대로 계승.

### 2.2 API (제네릭 옵션)

```
struct DSSegmentedChips<Option: Hashable>: View
```

| 파라미터 | 타입 | 설명 |
|---|---|---|
| `options` | `[Option]` | 표시 순서대로 |
| `selection` | `Binding<Option?>` | 단일선택. 같은 값 재탭 시 nil 토글(기존 동작 유지) |
| `label` | `(Option) -> String` | 옵션→라벨 텍스트 |
| `tint` | `(Option) -> DynamicColor?` | 옵션별 선택색(nil이면 semantic primaryTint). 대변색 스와치 주입용 |
| `spacing` | `CGFloat` = `theme.space.sm(8)` | 칩 사이 간격(바깥 여백 아님) |
| `compact` | `Bool` = `false` | true면 라벨 폰트·칩 좌우 패딩 축소(5등분 색 행 대응) |

호출 시그니처(참고, 구현 아님):
- `DSSegmentedChips(options: DiaperAmount.allCases, selection: $amount, label: \.displayName)`
- `DSSegmentedChips(options: StoolColor.diaperColorCases, selection: $color, label: \.diaperColorLabel, tint: { theme.color.swatch(for: $0.stoolSwatch) }, compact: true)`

### 2.3 레이아웃 규칙
- 루트: `HStack(spacing: spacing) { ForEach(options) { chip.frame(maxWidth: .infinity) } }`.
- 각 칩: 기존 `DSChip(variant: .selectable, tint:)`을 쓰되 **캡슐이 균등폭을 꽉 채우도록** `.frame(maxWidth: .infinity)`를 칩 바깥에 적용. (현재 `DSChip`은 라벨폭+`paddingX(14)`라 균등 아님 → 래핑으로 해결. `DSChip` 내부 수정 불필요.)
- **`Spacer()` 금지**: 현재 `DiaperInputSheet`가 `HStack{ …chips… ; Spacer() }`로 좌측정렬 시키는데, 균등폭에서는 `Spacer` 제거(있으면 균등 깨짐).
- **가로스크롤 금지**: 대변색 5개도 `ScrollView(.horizontal)`을 걷어내고 **한 줄 5등분**.

### 2.4 5등분(대변색) 좁은 폭 대응 — `compact`
색 라벨: 황금똥/초록색/검은색/붉은색/보통(2~3글자). 화면폭 375pt 기준 사용가능폭 ≈ 375 − 16×2(screenPaddingX) = 343pt. 5칩 + 간격 4개:
- `compact` 미적용 시: (343 − 8×4)/5 = **62.2pt/칩**. 캡슐 좌우 14패딩 제하면 라벨 가용 ≈ 34pt → 3글자(12pt semibold) 약 27~33pt로 **아슬함**.
- 그래서 색 행에는 **`compact: true`** 적용:
  - 칩 사이 간격 `spacing`을 `sm(8)` → **`xs(4)`** 로.
  - 칩 좌우 내부 패딩을 `14` → **`8`** (compact일 때 `DSChip` 래퍼에서 `.padding(.horizontal, -6)` 대신, 세그먼트가 자체 캡슐을 그리거나 라벨 `minimumScaleFactor(0.85)` 적용). **권장: `Text(...).lineLimit(1).minimumScaleFactor(0.85)`** 로 폰트 자동축소(가로스크롤보다 우선).
  - 재계산: (343 − 4×4)/5 = **65.4pt/칩**, 라벨 가용 ≈ 49pt → 3글자 여유.

> 정리: **양(3)·질감(3)** 은 `compact:false`(간격 8), **대변색(5)** 은 `compact:true`(간격 4 + 라벨 minimumScaleFactor 0.85). 가로스크롤은 전 항목에서 제거.

### 2.5 접근성
- 칩 높이 `component.chip.height = 44` **유지**(HIG 최소 터치 44×44 충족). compact도 높이는 44 고정, 폭만 균등.
- 각 칩 `accessibilityAddTraits(.isButton)` + 선택 시 `.isSelected`.

### 2.6 값 요약표 (컴포넌트)

| 속성 | 일반(양·질감) | compact(대변색) |
|---|---|---|
| 칩 높이 | 44 | 44 |
| 칩 폭 | `maxWidth:.infinity`(균등) | `maxWidth:.infinity`(균등) |
| 칩 사이 간격 | `sm(8)` | `xs(4)` |
| 좌우 바깥 여백 | 호출부 `screenPaddingX(16)` | 동일 |
| 라벨 폰트 | captionStrong 12 semibold | 동일 + `minimumScaleFactor(0.85)` |
| 라운드 | Capsule(pill) | Capsule(pill) |
| 가로스크롤 | 없음 | 없음 |

---

## 3. 컴팩트 레이아웃 값 (RecordEditSheet / DiaperInputSheet)

목표: **`.medium` detent(화면 높이의 약 50%, ≈ 375~430pt 콘텐츠 영역)에서 기저귀 편집 전체(양·질감·색·시각·저장/삭제)가 스크롤/드래그 없이 한 화면.**

### 3.1 세로 간격 조정표

| 위치 | 현재 | 권장 | 근거 |
|---|---|---|---|
| 최상위 섹션 간 세로 간격 (`typeFields`↔`timeFields`, 그리고 양/질감/색 사이) | `space.lg = 24` | **`space.md = 16`** | 24는 폼에서 과함. 16이 섹션 구분 유지하면서 절약 |
| 섹션 헤더("양")↔칩 행 | RecordEditSheet `sm(8)` / DiaperInputSheet `xs(4)` | **`xs(4)` 로 통일** | 헤더와 칩은 한 덩어리로 붙이는 게 스캔성 좋음 |
| 그룹(양/질감/색) 내부 컨테이너 spacing | `md(16)` | **`md(16)` 유지**(그룹 사이) | |
| ScrollView 콘텐츠 top 패딩 | `md(16)` | **`sm(8)`** | 그래버 아래 여백은 시트가 이미 확보 |
| 저장/삭제 HStack top 패딩 | `sm(8)` | `sm(8)` 유지 | |

**핵심 변경 1줄**: `RecordEditSheet`의 `VStack(spacing: theme.space.lg)` → `theme.space.md`, 그리고 각 섹션 헤더-칩 간격을 `xs`로.

### 3.2 높이 예산(375×667, `.medium`≈333pt 가정, 기저귀=둘다)

| 요소 | 높이(약) |
|---|---|
| 그래버+상단 여백 | 24 |
| ScrollView top | 8 |
| 양: 헤더12 + 4 + 칩44 | 60 |
| 섹션간격 md | 16 |
| 질감: 헤더12 + 4 + 칩44 | 60 |
| 섹션간격 md | 16 |
| 대변색: 헤더12 + 4 + 칩44 | 60 |
| 섹션간격 md | 16 |
| 기록시간: 헤더12 + 4 + DatePicker(compact) ~34 | 50 |
| 저장/삭제: top8 + 버튼56 + 하단여백 | 64+ |
| **합계** | **≈ 374 + 하단여백** |

`.medium`이 기기별로 333~430pt 편차가 있어 **경계선**이다. 세이프에어리어까지 감안하면 아래 detent 조정을 병행 권장.

### 3.3 detent 조정안 (권장)
- 현재: `detents: [.medium, .large]`.
- **권장: `detents: [.fraction(0.62), .large]`** (또는 `.height(430)`+`.large`). `.medium`(0.5)은 콘텐츠가 아슬하므로 **약 0.6~0.65 고정 높이 detent**를 기본으로 두면 "한 번에 다 보이게" 요구를 안정적으로 충족.
- 기본 선택 detent를 이 fraction으로 열도록 시트 옵션에 `selection`/기본값 지정(현재 옵션엔 selection 바인딩 없음 → `DSBottomSheetOptions`에 `defaultDetent` 추가 여지. 범위 밖이면 detent 집합만 `[.fraction(0.62), .large]`로 바꿔도 첫 detent가 기본이 됨).
- 기저귀 **소변**(질감·색 없음)은 콘텐츠가 짧아 `.medium`으로도 충분 → detent 집합만 넓혀두면 자연 대응.

---

## 4. 하단 버튼 세이프에어리어 처리

문제: 저장/삭제 HStack 하단이 `.padding(.bottom, md=16)`뿐이라, 홈 인디케이터(하단 safe area ~34pt) 위에 버튼이 겹쳐 터치 실패.

### 4.1 권장 처리
- 저장/삭제 `HStack`에 **safe area 하단을 반영한 여백**:
  - `@Environment(\.self)` 대신 `GeometryReader`의 `safeAreaInsets.bottom` 또는 `.safeAreaPadding(.bottom)` 사용.
  - 값: **`.padding(.bottom, max(theme.space.md(16), safeAreaBottom))`** — 인디케이터 있는 기기는 34로, 없는 기기는 16으로.
- 또는 더 단순히: 저장/삭제 바를 `VStack` 바닥에 두되 `.padding(.bottom, theme.space.md)` + 시트 컨테이너에서 `.ignoresSafeArea` 하지 않기(기본). SwiftUI `sheet`는 기본적으로 하단 safe area를 존중하므로, **가장 안전한 최소 변경은 `.padding(.bottom, max(md, safeAreaBottom))`** 명시.
- 터치 타깃: 저장 버튼 `size: .lg` = 56pt, 삭제 56×56 유지(44+ 충족). 변경 없음.

### 4.2 값 요약

| 항목 | 값 |
|---|---|
| 버튼 바 top 패딩 | `sm(8)` |
| 버튼 바 bottom 패딩 | `max(md=16, safeAreaInsets.bottom)` |
| 저장 버튼 높이 | 56 (`.lg`) |
| 삭제 버튼 | 56×56 |
| 버튼 사이 간격 | `sm(8)` |

---

## 5. 전후 레이아웃 스케치 (ASCII)

### Before (현재)
```
┌───────── grabber ─────────┐
│  양                        │   ← 헤더-칩 간격 8
│ (적게)(보통)(많이)   ·글자폭 │
│                            │   ← 섹션 간격 lg(24) 큼
│  질감                      │
│ (묽음)(보통)(찰흙)         │
│                            │   ← lg(24)
│  대변 색                   │
│ (황금똥)(초록색)(검은…→ 스크롤│
│                            │
│  기록 시간 [ 09:30 ]        │
│        ⋯ 화면 경계 ⋯        │  ← 여기서 잘림
│  (드래그해야 아래가 보임)     │
│  [🗑] [     저장     ]       │  ← safe area에 걸림
└──── 홈 인디케이터 ────┘
```

### After (개선)
```
┌───────── grabber ─────────┐
│  양                        │  ← 헤더-칩 xs(4)
│ [ 적게 ][ 보통 ][ 많이 ]   │  ← 균등폭, 사이 8
│                            │  ← 섹션 md(16)
│  질감                      │
│ [ 묽음 ][ 보통 ][ 찰흙 ]   │  ← 균등폭
│                            │  ← md(16)
│  대변 색                   │
│[황금똥][초록][검정][붉음][보통]│ ← 5등분 균등, 사이 4, compact
│                            │  ← md(16)
│  기록 시간 [ 09:30 ]        │
│ [🗑] [       저장        ]  │  ← 한 화면 안, 드래그 불필요
│      (bottom = max16,safe)  │  ← 인디케이터 안 겹침
└──── 홈 인디케이터 ────┘
```

---

## 6. 적용 범위 & 파일

| 파일 | 변경 |
|---|---|
| `zzippu/Shared/DesignSystem/Components/Inputs/DSSegmentedChips.swift` | **신규** — §2 컴포넌트 |
| `zzippu/Feature/Recording/RecordEditSheet.swift` | 기저귀 `diaperFields`의 양/질감/색 HStack → `DSSegmentedChips`. 섹션 spacing `lg→md`, 헤더-칩 `sm→xs`. 저장/삭제 bottom 패딩 §4. (**기저귀 우선**) |
| `zzippu/Feature/Diaper/DiaperInputSheet.swift` | 동일 원칙 적용. `Spacer()` 제거, 가로스크롤 제거, `DSSegmentedChips` 사용. 저장 버튼 bottom §4 |
| `zzippu/.../HomeView`(시트 여는 곳) 또는 `DSBottomSheetOptions` | detent를 `[.fraction(0.62), .large]`로(§3.3) |

### 6.1 후속(범위 밖, 권고)
- `FeedingInputSheet` / `PlayInputSheet` / `RecordEditSheet`의 모유(좌·우·양)·놀이 종류 칩도 **동일 `DSSegmentedChips`** 로 통일(이미 `.frame(maxWidth:.infinity)`를 개별 적용 중이므로 컴포넌트로 치환만 하면 톤·간격 일관성 확보). 우선순위는 기저귀 이후.
- 분유 프리셋(`.quick` 8칩)은 **가로스크롤 유지**(개수 많고 균등 부적합) — 이 스펙 대상 아님.

---

## 7. HIG·DS 정합 체크
- 모든 수치는 theme 토큰 사용(하드코딩 금지). compact 축소도 `xs(4)` 토큰 재사용.
- 터치 타깃 44pt 유지(HIG). 저장/삭제 56pt.
- 신규 컴포넌트는 `Shared/DesignSystem/Components/Inputs/`.
- 선택/비선택 색은 기존 `DSChip .selectable` 재사용 → 다크모드·도메인 tint 자동 계승.
</content>
</invoke>
