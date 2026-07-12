# WEB_PARITY_PLAN — iOS를 웹 타이포·간격에 정밀 일치시키기

> 목적: iOS SwiftUI 앱("먹놀잠/찌뿌둥")의 폰트 크기·weight·패딩을 **웹과 1:1로 수렴**시킨다.
> 현재 iOS는 `Font.system(.body)` 같은 **Dynamic Type TextStyle**을 쓰기 때문에 기본 크기에서 웹보다 크고, weight도 과하게 무겁다 → "바보스러움"의 정체.
> 이 문서는 **표 그대로 `tokens.json` + 2개 컴포넌트만 고치면** 웹과 같아지도록 구체적 before→after를 제공한다. (코드 금지, 지침만.)

## 0. 배경 사실 (확정 분석 — 재조사 불필요)

**웹 본문 타이포 분포(사용 횟수):**

| Tailwind | px | 사용 횟수 | 성격 |
|---|---|---|---|
| text-sm | 14 | **215 (최다)** | 본문 지배 |
| text-xs | 12 | **162** | 보조 텍스트 |
| text-lg | 18 | 32 | 카드 타이틀 |
| text-base | 16 | 24 | 강조 본문 |
| text-2xl | 24 | 13 | 중형 숫자 |
| text-4xl | 36 | 11 | 대시보드 큰 숫자 |
| text-xl | 20 | 9 | 소제목 |
| text-3xl | 30 | 6 | 대형 숫자 |

→ **웹은 작고 촘촘**하다. 본문 = 14, 보조 = 12가 전체를 지배.

**웹 weight 분포:** medium(500) **118회 (최다)**, semibold(600) 83, bold(700) 43.
→ **과굵지 않다.** 기본은 medium, 강조만 semibold, bold는 큰 숫자·타이틀 한정.

**iOS 현재 문제(Typography.generated.swift):**
`.system(.body)`=17pt, `.system(.callout)`=16, `.system(.caption)`=12, `.system(.headline)`=17(semibold), `.system(.title3)`=20, `.system(.largeTitle)`=34.
즉 **역할 대부분이 웹보다 1~3pt 크고**, headline/title에 semibold·bold가 과하게 걸려 무겁다. Dynamic Type이라 사용자 설정에 따라 더 커져 웹과 계속 어긋난다.

**핵심 결정:** Dynamic Type TextStyle 매핑을 **고정 pt(fixed size)** 로 전환하되, `dynamicTypeSize(...상한)`으로 접근성만 제한적으로 허용(신생아 아빠 가독성 배려, 12 미만 금지).

---

## 1. 타이포 크기표 (핵심 산출) — before → after

`primitive.font.scale`(기준 pt)과 `semantic.typography`(역할)를 웹 px에 수렴. **생성기가 TextStyle이 아니라 고정 pt로 방출**하도록 바꾸는 것이 전제(§6 참조).

### 1-a. semantic.typography 역할별 (실제 렌더 pt 기준)

| 역할(role) | 현재 iOS 렌더 pt (TextStyle) | 현재 weight | **after pt (웹 고정)** | **after weight** | 웹 대응 | 근거 |
|---|---|---|---|---|---|---|
| `body` | 17 (.body) | regular | **14** | **medium(500)** | text-sm | 본문 지배(215회). 웹 기본이 medium |
| `bodyStrong` | 17 (.body) | semibold | **14** | **semibold(600)** | text-sm semibold | 강조 본문 |
| `callout` | 16 (.callout) | regular | **14** | medium | text-sm | body와 통합 성격. 인풋은 §3 예외 |
| `headline` | 17 (.headline) | semibold | **16** | **semibold** | text-base semibold | 카드 내 소제목. 17→16, bold 아님 |
| `title` | 20 (.title3) | semibold | **18** | **semibold** | text-lg | 카드 타이틀(32회) |
| `caption` | 12 (.caption) | regular | **12 유지** | regular | text-xs | 보조(162회). 하한 유지 |
| `captionStrong` | 12 (.caption) | semibold | **12 유지** | **medium→semibold 중 semibold 유지** | text-xs semibold | 섹션헤더·상태필 |
| `label` | 11 (.caption2) | medium | **12로 상향** | medium | text-xs | **11→12**: 신생아앱 가독성 하한, 12 미만 금지 |
| `mono` | 11 (.caption2) | medium | **12로 상향** | medium(tabular) | 타임라인 시각 | 11→12, 하한 |
| `display` | 34 (.largeTitle) | bold | **36 (택1)** | **bold** | text-4xl | 대시보드 큰 숫자. §1-c 참조 |

### 1-b. primitive.font.scale 조정 (표의 근원값)

`semantic.typography`가 참조하는 scale 값 자체는 **대부분 이미 웹 px과 일치**(caption 12, title3 18, display 36). 문제는 **생성기가 pt를 무시하고 TextStyle로 매핑**한다는 점(§6). scale에서 손댈 값:

| scale 키 | 현재 값 | after | 이유 |
|---|---|---|---|
| `body` | 16 | **14** | 웹 본문 text-sm. 이게 가장 큰 임팩트 |
| `callout` | 16 | **14** (단, input `minFontSize`는 16 유지) | 본문 통일. 인풋 자동줌 방지값만 분리 |
| `headline` | 17 | **16** | text-base |
| `caption2` | 11 | **12** | label/mono 하한 승격 |
| `title3` | 18 | 18 유지 | 이미 일치 |
| `caption` | 12 | 12 유지 | 이미 일치 |
| `display` | 36 | 36 유지(또는 30, §1-c) | 이미 일치 |

> 주의: `component.input.minFontSize`는 `{primitive.font.scale.callout}`을 참조 중. callout을 14로 낮추면 인풋이 16pt 자동줌 방지선을 잃는다. → **minFontSize는 `{primitive.font.scale.body}`가 아니라 별도 16 고정(callout 참조 끊기)** 으로 바꿔야 함. 이 한 줄이 회귀 포인트.

### 1-c. display 36 vs 30 택1 지침

- 대시보드 **큰 숫자(총 수유량 ml 등)**: 웹 text-4xl(36) 사용처가 11회로 3xl(6회)보다 많음 → **36 유지 권장**.
- 화면이 좁아 36이 넘칠 우려가 있는 보조 대형 숫자에만 30 변형이 필요하면 `displayCompact`(30) 역할을 신설하되, 지금은 **36 단일 유지**로 충분.

---

## 2. weight 지침 — 과잉 bold 회수

원칙: **medium이 기본, semibold는 강조, bold는 "큰 숫자/최상위 타이틀"에만.**

| 상황 | 현재 | after | 조치 |
|---|---|---|---|
| 본문(body) | regular | **medium(500)** | 웹 최다 weight에 맞춤. `weight.regular`→`weight.medium` |
| headline | semibold | semibold **유지** | 단 17→16pt로 축소(§1)로 무게감 완화 |
| title | semibold | semibold 유지 | ok |
| display(큰 숫자) | bold | bold **유지** | bold 정당 사용처 |
| label/캡션 강조 | medium/semibold | 유지 | ok |

**과잉 bold 회수 지침(피처 코드 점검 대상):**
- 피처 뷰에서 `.fontWeight(.bold)` / `.bold()`를 **직접** 붙인 곳은 전수 검토 → 큰 숫자·화면 타이틀이 아니면 제거하고 semantic typography 역할에 위임.
- `.font(.system(size:weight:))`로 **토큰 우회**한 곳도 회수 대상(SSOT 위반).
- 원칙: 피처는 weight를 직접 지정하지 않는다. `theme.typography.body/headline/...`만 쓴다.

---

## 3. 패딩 / 간격 — 웹(p-3/4/5, gap-2/3)에 맞춤

`primitive.space`·`semantic.space`는 **이미 웹 Tailwind와 정렬**되어 있어 값 변경은 거의 불필요. 문제는 **피처가 `.padding()`(기본 16) 남발**로 웹보다 헐렁해지는 것.

| 요소 | 웹 기준 | 대응 토큰(현재) | 조치 |
|---|---|---|---|
| 카드 내부 | p-5 = 20 | `card.padding = cardPadding(20)` | 유지. 피처의 임의 `.padding()` 제거 |
| 페이지 좌우 | px-4 = 16 | `screenPaddingX = 16` | 유지 |
| 리스트 행 | py-3 px-4 | `listRow paddingY=12 paddingX=16` | 유지 |
| 버튼 좌우 | px-5 | `button.paddingXMd = 20` | 유지 |
| 스택 간격 | gap-2 / gap-3 | `stackGapSm=8 / stackGapMd=12` | 유지 |
| 칩 | px 알약 | `chip.paddingX=14` | 유지 |

**과한 곳 지적(값이 아니라 사용 규율):**
- 피처에서 인자 없는 `.padding()`(= 전방위 16) 사용 → **역할 토큰으로 교체**. 카드 안이면 이미 card.padding이 있으므로 **중복 패딩 제거**.
- `DSBottomSheetContainer`의 `content().padding(.bottom, theme.space.md)`만 있고 **상단/좌우 패딩 규칙이 없어** 콘텐츠가 시트 상단에 붙는 문제 → §4.
- gap을 `VStack(spacing: 16)`처럼 하드코딩한 곳 → `stackGapMd(12)`/`sectionGap(16)` 역할로.

---

## 4. 모달(DSBottomSheet) 2건 수정

파일: `zzippu/Shared/DesignSystem/Components/Overlays/DSBottomSheet.swift`

### (a) 좌측 X 닫기 버튼 제거
- 현재 `DSBottomSheetContainer.body`의 header에서 `title` 있을 때 `DSIconButton(systemName: "xmark")`(line 68)를 렌더.
- 네이티브 시트는 이미 **grabber(드래그 인디케이터) + 스와이프 다운 + 스크림 탭**으로 닫힌다 → X 버튼은 중복이며 웹에 없다.
- **조치:** header의 `Spacer()` + `DSIconButton` 블록 제거. `Text(title)`만 남기고 좌측 정렬. (`isPresented` 바인딩은 X 제거 후 컨테이너에서 미사용이면 정리.)

### (b) 콘텐츠 상단 패딩 일관 규칙
- 현재 `content()`에 `.padding(.bottom, theme.space.md)`만 적용 → **상단·좌우 패딩 없음**. title이 없는 시트는 콘텐츠가 시트 최상단(grabber 바로 아래)에 붙는다.
- **조치(규칙 확정):** 콘텐츠 래퍼에 **일관 패딩**을 컨테이너 레벨에서 부여한다.
  - `.padding(.horizontal, theme.space.cardPadding /*20, 웹 시트 px-5*/)`
  - `.padding(.top, title != nil ? theme.space.componentPaddingY /*12, 헤더와 간격*/ : theme.space.cardPadding /*20, 헤더 없을 때 grabber 아래 여백*/)`
  - `.padding(.bottom, theme.space.cardPadding)` (기존 `space.md` 대신 시트 표준 20으로 통일 + safe-area는 `.safeAreaPadding`/`.padding(.bottom)`으로 별도 보완)
- 결과: 헤더 유무와 무관하게 콘텐츠가 시트 가장자리에 붙지 않고 웹 시트(p-5)와 동일한 여백을 갖는다.
- 피처가 시트 콘텐츠 안에서 다시 `.padding()`을 걸지 않도록 주석/문서화(중복 패딩 방지).

> `component.bottomSheet.padding`(현재 `cardPadding`=20) 토큰이 이미 존재하므로 **이 토큰을 실제로 컨테이너에서 사용**하도록 배선하는 것이 핵심. 지금은 토큰이 있는데 컨테이너가 `space.md`만 쓰고 있어 불일치.

---

## 5. 핵심 변경 Top 5 (웹과 동일해지는 임팩트순)

1. **body 16→14pt + weight regular→medium** — 웹 본문 text-sm(215회)·medium(118회)에 직결. 화면 전체 인상이 가장 크게 바뀜("작고 촘촘"해짐).
2. **생성기를 TextStyle→고정 pt로 전환**(§6) — 이게 안 되면 위 표가 무의미. Dynamic Type 스케일이 웹과 계속 어긋나는 근본 원인 제거. 접근성은 상한만 허용.
3. **headline 17→16, title/무게 정돈 + 과잉 bold 회수** — 웹 text-base/lg 수준으로 위계 하향, "무거움" 해소.
4. **DSBottomSheet X 버튼 제거 + 상단 패딩 일관 규칙** — 모달이 웹과 구조·여백까지 일치, 콘텐츠 붙는 버그 해소.
5. **label/mono 11→12 하한 + 피처 하드코딩(padding/weight/font.system) 회수** — 신생아 가독성 하한 확보 + SSOT 복원.

---

## 6. 생성기 전제(개발자 확인용) — TextStyle → 고정 pt

`tools/gen-tokens.mjs`가 현재 `primitive.font.scale`을 **Font.TextStyle**로 매핑(`.system(.body)` 등)한다. 이 문서의 pt 표가 실제로 적용되려면 생성기 출력이 다음처럼 **고정 사이즈**여야 한다(개념 예시, 실제 코드는 개발자가):

```
// after 개념: 고정 pt + weight + (필요 시) 상한
let body: Font = .system(size: 14, weight: .medium)
let headline: Font = .system(size: 16, weight: .semibold)
let title: Font = .system(size: 18, weight: .semibold)
let display: Font = .system(size: 36, weight: .bold, design: .rounded)  // + dsDynamicTypeCap
```

- 접근성: 전면 Dynamic Type 대신 `.dynamicTypeSize(...DynamicTypeSize.xLarge)` 정도 **상한만** 전역 적용(신생아 아빠 배려하되 웹 레이아웃 유지). 큰 숫자/mono는 기존 `dsDynamicTypeCap`(.xxLarge) 재사용.
- 12 미만 금지: label/mono 하한 12로 승격했으므로 상한만 걸면 하한 위반 없음.
- **SSOT 유지:** 값은 전부 `tokens.json`에서 온다. 생성기 매핑 방식(TextStyle→고정 pt)만 바꾸고, pt 값은 §1-b 표대로 tokens.json에서 조정.

## 7. 개발자 작업 체크리스트 (표대로만)

- [ ] `tokens.json` `primitive.font.scale`: body 16→14, callout 16→14, headline 17→16, caption2 11→12 (§1-b).
- [ ] `tokens.json` `semantic.typography.body.weight`: regular→**medium** (§2).
- [ ] `tokens.json` `component.input.minFontSize`: callout 참조 끊고 **16 고정**(자동줌 방지 유지) (§1-b 주의).
- [ ] `gen-tokens.mjs`: typography 방출을 TextStyle→**고정 pt**로 (§6). 재생성 `node tools/gen-tokens.mjs`.
- [ ] 전역 `.dynamicTypeSize(...xLarge)` 상한 적용 지점 확정 (§6).
- [ ] `DSBottomSheet.swift`: X 버튼 제거(§4a) + 콘텐츠 상단/좌우 패딩 일관 규칙 배선(§4b, `bottomSheet.padding` 토큰 사용).
- [ ] 피처 전수 점검: 직접 `.bold()`/`.fontWeight`/`.font(.system(size:))`/인자없는 `.padding()` 회수 (§2, §3).
