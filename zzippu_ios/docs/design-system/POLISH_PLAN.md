# POLISH_PLAN — 찌뿌둥 UI 정제안

> 목적: "투박하다(clunky/unrefined)"는 피드백의 **구체적 원인**을 실제 토큰·컴포넌트 값 근거로 진단하고, **토큰 우선** 정제안을 제시한다.
> 원칙: 3계층 토큰(primitive→semantic→component)·크로스플랫폼 SSOT(`tokens.json`) 구조 유지, **값만 정제**. 신생아앱 톤(부드러움·신뢰·다크 저눈부심)·WCAG 대비 준수.
> 근거 파일: `docs/design-system/tokens.json`, `zzippu/Shared/DesignSystem/Tokens/*.generated.swift`, `zzippu/Shared/DesignSystem/Components/*`, `zzippu/Feature/{Auth,Home,Dashboard}/*`.

---

## 0. 관찰 — 실제 렌더(로그인 화면)

라이트(`/tmp/design_login.png`)·다크(`/tmp/design_login_dark.png`) 공통:

1. **비활성 Primary 버튼이 미완성처럼 보임** — "인증코드 받기"가 연한 파랑 배경 + 흰 글씨. 라이트에서 대비가 낮아 글씨가 배경에 녹고, "고장난 버튼"처럼 읽힘. (원인: primary가 blue-400인데 disabled를 `opacity 0.5`로만 처리 → 연파랑+흰글씨 → 대비 붕괴)
2. **모든 요소가 평평** — 입력필드·버튼에 그림자가 전혀 없다. 필드는 얇은 테두리 하나에만 의존해 배경(gray-50)에서 거의 떠오르지 않는다.
3. **풀폭 버튼이 무겁다** — 좌우 24pt 여백 안에서 화면폭 전체를 채우는 사각 덩어리. radius 12가 56pt 높이 대비 작아 각져 보인다.
4. **타이포 위계가 밋밋** — "찌뿌둥" 타이틀은 굵지만(수동 `.bold`), 그 아래 위계 단계가 body/caption로 급격히 떨어져 중간 톤이 없다.
5. **여백 리듬 헐렁** — 로고블록 아래 56pt, 필드-버튼 사이 32pt(`space.xl`)로 요소들이 관계없이 흩어져 그룹감이 약하다.

---

## 1. 진단 요약 — 투박함의 핵심 원인 Top 8 (근거값)

### ★1. 타이포 위계가 코드상 완전히 죽어 있다 (가장 치명적, 전 화면 파급)
- `Tokens/Typography.generated.swift`: **모든** 스타일이 `.weight(.regular)`로 생성됨.
  - `bodyStrong`, `title`, `headline`, `display`, `captionStrong`, `label` 이 tokens.json에서는 semibold/bold/medium인데 **전부 regular로 덮어씀**. → 생성기 버그.
- 결과: `DSListRow`/`TimelineRow`/`DSChip`/`DSSectionHeader` 등에서 "Strong" 스타일을 써도 굵기 차이가 안 남 → **모든 텍스트가 한 톤으로 뭉개짐**(밋밋함의 근원).
- 피처들은 이를 우회하려 **원시 폰트를 하드코딩**: `MetricCard`·`DashboardSummaryCards`·`GrowthDetailView`가 `.font(.system(size: 28/32, weight: .bold, design: .rounded))`. → 토큰 파이프라인을 건너뛰어 화면마다 크기·굵기가 제각각(28 vs 32 vs 22), rounded 디자인이 여기만 섞여 통일성 붕괴.
- `LoginView`도 `theme.typography.display` 뒤에 `.fontWeight(.bold)`를 수동으로 덧붙여야 굵게 나옴 = 토큰이 신뢰 불가하다는 방증.

### ★2. 그림자가 사실상 없다 — 깊이(입체감) 부재
- `shadow.sm = opacity 0.05, y1, blur2`. 카드의 유일한 그림자인데 gray-50 배경 위에서 **육안으로 거의 안 보임**.
- `DSCard`는 `border(1px) + shadow.sm`을 **동시** 적용 → 그림자가 안 보이니 결국 테두리에만 의존 → "선으로 그린 박스" 느낌(HIG/건강앱의 부드러운 부양감과 반대).
- `DSTextField`·`DSButton`·`BigActionButton`엔 그림자 자체가 없음 → 컨트롤이 배경에 붙어 있음.

### ★3. 비활성/보조 상태의 대비 처리가 조잡
- 비활성 버튼: `opacity 0.5`만 곱함(`DSButton`, `button.disabledOpacity`). primary가 blue-400(연한 파랑)이라 0.5를 곱하면 **연파랑+흰글씨** → 로그인 관찰 #1의 원인. 대비비 WCAG 미달 추정.
- 올바른 비활성 패턴(별도 disabled 배경/전경 토큰)이 없음 → 전 버튼에 동일 문제.

### ★4. 테두리가 배경 대비 과하거나 이중이라 지저분
- `DSCard` border = `semantic.border`(gray-100) + 그림자. 카드가 흰색이고 배경이 gray-50이면 이미 표면 대비가 있는데 테두리까지 그려 **선이 둘러쳐진 투박함**.
- `DSTextField`·`BigActionButton`은 `borderStrong`(gray-200) 1.5px → 필드 테두리가 도드라져 "폼 요소" 티가 강함(건강앱은 채움 배경 + 테두리 없음/약함).

### ★5. radius가 요소 크기와 안 맞음
- 버튼/입력 radius=12(`control`). 하지만 **버튼 lg 높이=56pt**. 56pt 컨트롤에 12 radius는 각져 보임(무거움의 원인). 44pt 컨트롤엔 12가 적당하나 56엔 부족.
- `BigActionButton`도 `radius.control`(12)에 세로 패딩 16 → 큰 타일에 작은 라운드.

### ★6. 간격 리듬이 상황따라 튄다
- `TimelineItemRow` 좌우 패딩 = `componentPaddingX`(16)인데, `DayTimelineSection`이 이를 다시 `screenPaddingX`(16)로 감쌈 → **행 실제 좌우 여백 32pt**로 과함. 반대로 도트-라벨 간격은 `stackGapMd`(12)로 헐렁.
- 로그인: 로고블록-필드 56, 필드-버튼 32(`xl`) → 4pt 리듬(4·8·12·16·24·32)은 지키지만 **큰 값들만 골라 써** 요소 간 관계가 안 읽힘.
- `DSStatusPill` paddingY=`space.1`(4) vs paddingX=`space.3`(12) → 알약이 상하로 눌린 납작한 비율.

### ★7. 도트/아이콘이 너무 작아 빈약
- 타임라인 도트 8pt 고정(`timelineRow.dotSize`), idle 6pt. 16pt 텍스트 옆 8pt 원은 **점처럼 왜소**해 도메인 색 식별성·리듬이 약함.
- `DSListRow` chevron 13pt semibold — 회색 textTertiary라 거의 안 보임.

### ★8. 모션 피드백이 얕고 불균일
- 버튼 press `scale 0.97`, 카드 `0.98`, duration 0.12s easeOut — 작동은 하나 **배경색 변화가 없어**(primary만 pressed색 있고 secondary/tertiary/BigActionButton은 무변화) 눌린 느낌이 약함. `BigActionButton`은 `.buttonStyle(.plain)`이라 **press 피드백 전무**.

---

## 2. 정제안 (토큰 우선 · before→after)

### 2-A. 최우선 토큰 변경 (전 컴포넌트 파급)

#### T1. 타이포 weight 파이프라인 복구 — **가장 임팩트 큼**
`Typography.generated.swift`가 tokens.json의 weight를 무시하는 **생성기 버그를 수정**(값 정제가 아니라 SSOT 의도 복원). 각 스타일에 지정 weight 적용:

| 스타일 | before(생성됨) | after(tokens.json 의도) |
|---|---|---|
| `display` | `.regular` | **`.bold`** + `.rounded` design (큰 숫자 전용) |
| `title` | `.regular` | **`.semibold`** |
| `headline` | `.regular` | **`.semibold`** |
| `bodyStrong` | `.regular` | **`.semibold`** |
| `captionStrong` | `.regular` | **`.semibold`** |
| `label` | `.regular` | **`.medium`** + `tracking(+0.3)` |
| `body`/`caption`/`callout` | `.regular` | 유지(regular) |

- 근거: 위계는 **크기보다 굵기 대비**가 세련됨을 만든다. bodyStrong(semibold)↔body(regular) 대비가 살아나면 리스트·타임라인·카드 제목이 즉시 정돈됨.
- 파급: 수정 즉시 `LoginView`의 수동 `.fontWeight(.bold)`, Dashboard의 하드코딩 폰트를 **토큰으로 회수** 가능(별도 정리 항목 R1).
- `display`에 `.rounded` 흡수 → Dashboard 큰 숫자가 토큰 하나로 통일(현재 3곳 제각각).

#### T2. 그림자 강화 + 카드 "테두리 OR 그림자" 택일
primitive.shadow 값 상향(부드럽게, 다크 저눈부심 유지):

| 토큰 | before | after |
|---|---|---|
| `shadow.sm` | y1 blur2 op0.05 | **y2 blur8 op0.06** (넓고 옅게 — iOS식 부양) |
| `shadow.md` | y4 blur6 op0.08 | **y4 blur16 op0.08** |
| `shadow.lg` | y10 blur15 op0.10 | y8 blur24 op0.10 (유지급) |

- `component.card`: **테두리를 기본 제거**하고 그림자로만 부양. `border`는 다크모드에서만(그림자가 안 보이므로) 얇게 유지 → 라이트는 그림자, 다크는 border-only. `DSCard`의 `border+shadow 이중`을 없애 지저분함 제거.
- 근거: 애플 건강앱 카드는 테두리 없이 그림자만으로 뜬다. 이중 처리 제거가 "선으로 그린 박스" 느낌을 없앰.
- 신생아앱 톤: opacity를 0.06~0.08로 낮게 유지해 과한 그림자 배제(부드러움 보존).

#### T3. 비활성 상태 전용 토큰 신설 (opacity 곱셈 폐기)
semantic에 추가 → component.button이 참조:

| 신규 토큰 | light | dark |
|---|---|---|
| `color.primaryDisabledBg` | gray-200 | gray-700 |
| `color.onPrimaryDisabled` | gray-400 | gray-500 |

- `DSButton` disabled: `opacity 0.5` → **중립 회색 배경 + 회색 글씨**로 교체. "연파랑+흰글씨"의 저대비 문제 해소, 명확히 "지금 못 누름"으로 읽힘(로그인 관찰 #1 직결).
- 대비: 회색-회색은 의도적 저대비(비활성 신호)이며 텍스트 판독은 유지되는 조합.

#### T4. radius 크기 연동 — 대형 컨트롤 라운드 상향
| 토큰 | before | after |
|---|---|---|
| `radius.md`(control) | 12 | 12 유지(44pt 컨트롤용) |
| `radius.lg`(card) | 16 | 16 유지 |
| **신규 `radius.control-lg`** | — | **16** (56pt 버튼·BigActionButton 전용) |

- `button.heightLg`/`BigActionButton`가 새 `control-lg`(16) 참조 → 56pt 덩어리의 각진 느낌 완화, 부드러운 신뢰감.

#### T5. 도트/보조 아이콘 크기 상향
| 토큰 | before | after |
|---|---|---|
| `timelineRow.dotSize` | 8 | **10** |
| `timelineRow.dotSizeIdle` | 6 | **8** |
| `size.dotMd` | 8 | 10 |

- 16pt 텍스트 옆에서 도트가 "왜소한 점"→"또렷한 색 마커"로. 도메인 색 식별성·리듬 개선.

### 2-B. 컴포넌트별 조정 (토큰 기반)

- **DSButton**
  - 비활성: T3 토큰 적용(회색 배경/글씨).
  - 프레스: 모든 variant에 배경 변화 추가 — secondary/tertiary도 pressed 시 `surfaceSunken→borderStrong` 또는 `primaryTint`로 살짝 변화. scale은 0.97 유지.
  - lg 사이즈 radius = `control-lg`(16).
- **DSCard** — border 이중 제거(T2). `.plain`은 라이트=그림자만/다크=border만. `interactive` press 시 그림자 살짝 축소(눌림감).
- **DSTextField**
  - idle 배경을 `surface`→**`surfaceSunken`**(채움형 필드)로, 테두리는 idle에서 제거하고 **focus 시에만** primary 1.5px 링 표시. 근거: 건강앱식 채움 필드가 "밋밋한 테두리 박스"보다 세련·명확.
  - focus 링에 옅은 primaryTint 배경 얹어 포커스 가시성↑.
- **DSChip** — 선택 시 `bgSelected`(primaryTint)에 그림자 없이 fg=primary 유지 OK. idle fg를 textSecondary→**textPrimary 유지하되 굵기 medium**(label 토큰 medium 적용 후 자동 개선). paddingX 12→**14**로 알약 비율 개선.
- **DSStatusPill** — paddingY `space.1`(4)→**6**(신규 `space.1.5`=6 또는 `space.2`=8 검토)로 납작함 해소. captionStrong(semibold 복구) 적용.
- **TimelineItemRow / DayTimelineSection** — 이중 좌우 패딩 정리: 행은 `componentPaddingX` 제거하고 섹션의 `screenPaddingX` 하나만 → 실효 32pt→16pt. 도트-라벨 gap `stackGapMd`(12)→`stackGapSm`(8). 도트 T5 적용.
- **BigActionButton** — `.buttonStyle(.plain)` → press 피드백 추가(scale 0.97 + tint 진하게). radius `control`→`control-lg`(16). 활성 테두리 2px는 유지하되 비활성은 테두리 0(현재 OK).
- **DSListRow** — chevron 색 textTertiary→**textSecondary**, 두께 유지. divider 색 유지.
- **DSTabBar** — 비활성 fg `textTertiary`(gray-400/500)는 너무 흐림 → **textSecondary**로. 활성/비활성 대비는 색+굵기(이미 semibold)로 충분.

### 2-C. 로그인 화면 여백 리듬(피처 조정, 토큰 사용)
- 로고블록↔필드 56→**32**(`xl`), 필드↔버튼 32→**16**(`md`)로 좁혀 "입력 그룹"을 시각적으로 묶기. 버튼 아래 여백으로 그룹을 화면 하단에 정박.
- 좌우 패딩 `space.lg`(24)→`screenPaddingX`(16)로 통일(다른 화면과 리듬 일치).

---

## 3. 우선순위 (임팩트 순 = 파급 넓은 토큰부터)

| 순위 | 항목 | 이유 | 범위 |
|---|---|---|---|
| **P0** | **T1 타이포 weight 복구** | 전 텍스트 위계 부활. 최대 임팩트, 최소 위험(생성기 수정) | 앱 전체 |
| **P0** | **T3 비활성 토큰** | 로그인 첫인상 문제 직접 해결 | 전 버튼 |
| **P1** | **T2 그림자+카드 정리** | 평면→입체, 이중테두리 제거 | 전 카드·시트·토스트 |
| **P1** | T4 대형 radius / T5 도트 | 무거움·빈약함 완화 | 대형 버튼·타임라인 |
| **P2** | 2-B 컴포넌트 디테일 | 텍스트필드 채움·프레스·핀 밀도 | 개별 컴포넌트 |
| **P3** | R1 하드코딩 폰트 회수 | Dashboard 등 `.system(size:weight:)` → 토큰(display)로 | Dashboard·Login |
| **P3** | 2-C 로그인 여백 | 화면별 리듬 미세조정 | Auth |

> **R1(정리 부채):** T1 완료 후 `MetricCard`·`DashboardSummaryCards`·`GrowthDetailView`의 `.font(.system(size: 28/32, weight: .bold, design: .rounded))`와 `LoginView`의 수동 `.fontWeight(.bold)`를 `theme.typography.display`로 교체. 크기 통일 + rounded 일원화.

---

## 4. 개발 적용 순서

1. **`tokens.json` 정제**: shadow.sm/md 값 상향, `radius.control-lg`(16) 추가, `color.primaryDisabledBg`·`onPrimaryDisabled` 신설, `size.dotMd` 10, `chip.paddingX` 14, `statusPill.paddingY` 6.
2. **생성기(`tools/gen-tokens.mjs`) 수정**: `SemanticTypography` weight를 tokens.json `font.weight` 참조대로 출력하도록 버그 픽스(display=bold+rounded, title/headline/bodyStrong/captionStrong=semibold, label=medium+tracking). → 재생성.
3. **컴포넌트 리팩터**: DSButton(비활성/프레스/lg radius) → DSCard(테두리·그림자) → DSTextField(채움·포커스) → TimelineRow/DayTimelineSection(패딩·도트) → DSChip/DSStatusPill/DSTabBar/DSListRow.
4. **피처 회수(R1)**: Dashboard·Login 하드코딩 폰트 → 토큰. 로그인 여백 조정(2-C).
5. **검증**: 로그인 라이트/다크 재캡처로 비활성 버튼 대비·깊이 확인, WCAG 대비 재측정, Dynamic Type(display/mono cap 유지) 점검.

> SSOT 원칙 준수: 모든 값은 `tokens.json`에서 정의 → 생성기 → SwiftUI. 컴포넌트/피처는 semantic·component 토큰만 참조(하드코딩 폰트 제거로 위반 해소).
