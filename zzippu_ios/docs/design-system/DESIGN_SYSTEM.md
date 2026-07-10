# 먹놀잠(찌뿌둥) 디자인 시스템 — 토큰 체계 + 규칙

> 이 문서는 `tokens.json`(단일 원천)과 함께 읽는다. 토큰의 **철학·네이밍·크로스플랫폼 매핑·사용 규칙**을 정의한다.
> 컴포넌트 API는 `COMPONENTS.md`, 폴더/의존성 구조는 `ARCHITECTURE_DESIGN_SYSTEM.md` 참조.

---

## 0. 목적과 원칙

- **단일 원천(SSOT)**: 모든 색·간격·타이포·라운드·그림자·모션 값은 `tokens.json` 한 곳에서만 정의한다. SwiftUI·웹·(향후)SSR은 이 파일을 **읽어 생성**한다. 값을 코드에 직접 쓰지 않는다.
- **플랫폼 중립**: 토큰 이름은 특정 플랫폼(SwiftUI Color, Tailwind 클래스)에 종속되지 않는 역할 이름이다. 예: `semantic.color.primary`는 iOS에선 `Theme.color.primary`, 웹에선 `--color-primary`로 각각 생성된다.
- **신생아앱 UX 반영**:
  - **밤중 사용** → 다크모드는 1급 시민. 모든 semantic/component 토큰이 light/dark 쌍을 갖는다. 저눈부심을 위해 다크 배경은 순흑이 아닌 `gray-900/800` 계열.
  - **한손·초단위 기록** → 터치타깃 최소 44pt(`primitive.size.touchMin`), 주요 액션 56pt. 선택 칩도 44pt.
  - **부모의 신뢰** → 상태(저장중/오프라인) 색은 `status.info/warning`으로 일관.

---

## 1. 3계층 토큰 철학

```
primitive  →  semantic  →  component
(원시값)       (역할)         (컴포넌트별)
```

| 계층 | 역할 | 예 | 피처에서 참조? |
|---|---|---|---|
| **primitive** | 값의 저장소. 의미 없음. 팔레트·스케일. | `primitive.color.blue.400 = #60A5FA` | ❌ 금지 |
| **semantic** | 역할·의도. 라이트/다크 쌍. primitive를 참조. | `semantic.color.primary = {light: blue.400, dark: blue.500}` | ✅ 주 사용 |
| **component** | 컴포넌트 전용. semantic만 참조. | `component.card.bg = {semantic.color.surface}` | ✅ (해당 컴포넌트 내부) |

**왜 3계층인가**
- 리브랜딩: `primitive.color.blue.*`만 교체하면 primary가 파생된 모든 컴포넌트가 자동 변경.
- 다크모드: semantic에서 light/dark만 스위칭. 컴포넌트/피처 코드 무수정.
- 서버주도 테마: semantic 매핑을 런타임 주입으로 교체(§5.4).

### 참조 표기
`tokens.json`에서 `"value": "{primitive.color.gray.50}"`는 **참조**다. 생성기가 경로를 해석해 실제 값으로 치환한다. 라이트/다크가 있는 토큰은 `"value": { "light": "...", "dark": "..." }` 형태.

---

## 2. 네이밍 규칙

- 경로는 **dot 표기**, 계층부터: `<layer>.<category>.<...role>`. 예: `semantic.color.domain.feeding.formula.solid`.
- 색 역할 접미사: `fg`(전경/텍스트), `bg`(연한 배경), `solid`(채움 강조), `tint`(아주 연한 배경), `Pressed`(눌림).
- 상태: `status.{success|warning|danger|info}` — 의미 고정. **success=정상, warning=주의, danger=경고, info=중립정보**.
- 도메인: `domain.{feeding|diaper|stool|sleep|play}` — 기록 종류. 각기 `solid`/`tint`(스와치는 단일 값).
- 플랫폼 생성 시 관례 변환:
  - SwiftUI: 경로를 camelCase 프로퍼티로. `domain.feeding.formula.solid` → `Theme.color.domainFeedingFormula`(또는 중첩 구조체 `theme.color.domain.feeding.formula`).
  - 웹: 경로를 kebab CSS 변수로. `--color-domain-feeding-formula`.

---

## 3. 라이트/다크 & 접근성 (WCAG)

- **모든 semantic/component 색 토큰은 light/dark 두 값 필수.** 새 색 토큰 추가 시 두 값을 반드시 채운다(생성기가 누락을 검증).
- **대비 기준(WCAG 2.1 AA)**:
  - 본문 텍스트(textPrimary/Secondary on background/surface): 대비 ≥ 4.5:1.
  - 큰 텍스트(≥18pt semibold)·아이콘: ≥ 3:1.
  - `textTertiary`는 플레이스홀더/장식용으로만 — 본문 금지(대비 미달).
  - `onPrimary`(흰색) on `primary`(blue-400/500): AA 충족 확인됨.
- **색만으로 의미 전달 금지**: 상태 pill은 색+텍스트("적정"/"권장보다 적음"), 타임라인 도트는 색+라벨 텍스트를 병기(현재 웹도 동일).
- **stool.white** 스와치는 배경(surface)과 구분되지 않으므로 **테두리(borderStrong) 필수**(컴포넌트 규칙에 명시).
- **Dynamic Type**: iOS는 `semantic.typography.*`를 고정 pt가 아니라 대응 `Font.TextStyle`로 생성(§5.1)해 사용자 글자 크기를 존중. `display`/`mono` 등 tabular 필요 스타일만 예외적으로 크기 고정 + `.dynamicTypeSize(...)` 상한 지정.
- **Reduced Motion**: `primitive.motion` 사용부는 `@Environment(\.accessibilityReduceMotion)`(iOS)·`prefers-reduced-motion`(웹)에서 지속=0 또는 페이드로 대체.

---

## 4. 스케일 표 (구체 값)

### 4.1 간격 (space, 4pt 그리드)
| 토큰 | px/pt | 용도 |
|---|---|---|
| `space.1` | 4 | 미세 gap |
| `space.2` | 8 | 인라인 gap |
| `space.3` | 12 | stat 타일 패딩·행 패딩Y |
| `space.4` | 16 | 화면 좌우·섹션 gap |
| `space.5` | 20 | **카드 패딩(p-5)** |
| `space.6` | 24 | 큰 여백·empty state |
| `space.8` | 32 | |
| `space.12` | 48 | |

### 4.2 라운드 (radius)
| 토큰 | 값 | 용도 |
|---|---|---|
| `radius.sm` | 8 | 소형 |
| `radius.md` | 12 | **버튼·인풋(rounded-xl)** |
| `radius.lg` | 16 | **카드·타일(rounded-2xl)** |
| `radius.xl` | 24 | **바텀시트(rounded-3xl)** |
| `radius.full` | 9999 | pill·배지·아바타·도트 |

### 4.3 타이포 (semantic.typography → 기준 pt)
| 역할 | 기준 pt | weight | iOS TextStyle 매핑 | 용도 |
|---|---|---|---|---|
| `display` | 36 | bold | `.largeTitle`(tabular) | 대시보드 큰 숫자 |
| `title` | 18 | semibold | `.title3` | 카드 타이틀 |
| `headline` | 17 | semibold | `.headline` | |
| `bodyStrong` | 16 | semibold | `.body`(semibold) | 강조 본문·아기이름 |
| `body` | 16 | regular | `.body` | 본문 |
| `callout` | 16 | regular | `.callout` | 인풋(최소16) |
| `captionStrong` | 12 | semibold | `.caption`(semibold) | 상태 pill·섹션헤더 |
| `caption` | 12 | regular | `.caption` | 보조 텍스트 |
| `label` | 11 | medium | `.caption2` | 탭 라벨·배지 |
| `mono` | 11 | medium(mono) | monospaced caption2 | 타임라인 시각 |

### 4.4 그림자 (shadow)
| 토큰 | y / blur / opacity | 용도 |
|---|---|---|
| `shadow.sm` | 1 / 2 / 0.05 | 카드 |
| `shadow.lg` | 10 / 15 / 0.10 | 토스트·플로팅 배지 |
| `shadow.xl` | 20 / 25 / 0.12 | 바텀시트 |

### 4.5 모션 (motion)
| 토큰 | 값 | 용도 |
|---|---|---|
| `duration.fast` | 200ms | 버튼·토스트 |
| `duration.normal` | 300ms | 시트 전환 |
| `easing.spring` | response .35 / damping .85 | 시트·토글(SwiftUI) |
| `toastAutoDismissMs` | 3500 | 토스트 자동 소멸 |

---

## 5. 크로스플랫폼 매핑 규칙

`tokens.json`이 원천이고, 플랫폼별 산출물은 **생성(generated)**한다. 손으로 쓰지 않는다.

### 5.1 → SwiftUI (iOS)
생성기(스크립트 또는 수동 규칙)가 `tokens.json`을 읽어 `Shared/DesignSystem/Tokens/` 아래에 **생성 파일**을 만든다:
- **primitive** → `enum PrimitiveColor/Space/Radius/...`의 `static let`(원시 상수). 예: `static let blue400 = Color(hex: 0x60A5FA)`.
- **semantic 색** → `Theme` 구조체 프로퍼티. light/dark 두 값을 담고, 런타임에 `colorScheme`으로 선택. 예:
  ```
  // 생성 결과(의사코드)
  struct ThemeColor {
    let primary: DynamicColor   // DynamicColor(light: .blue400, dark: .blue500)
    ...
  }
  ```
  `DynamicColor`는 `Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })`로 해석 → 시스템 다크모드 자동 반영.
- **semantic.typography** → `Font` 팩토리. TextStyle 매핑(§4.3) 사용해 Dynamic Type 유지.
- **간격/라운드/그림자** → `CGFloat` 상수 / `ViewModifier`(그림자).
- 사용처: 컴포넌트/피처는 `@Environment(\.theme)`로 주입된 `Theme`만 참조(§5.4, COMPONENTS §테마주입).

### 5.2 → 웹 (CSS custom properties + Tailwind v4)
생성기가 `globals.css`에 **CSS 변수 블록**을 생성:
- primitive → `:root { --primitive-color-blue-400: #60A5FA; ... }`.
- semantic → `:root { --color-primary: var(--primitive-color-blue-400); ... }` / `.dark { --color-primary: var(--primitive-color-blue-500); ... }`.
- Tailwind v4는 `@theme` 블록에서 이 CSS 변수를 참조 → `bg-primary`, `text-status-danger-fg` 등 유틸리티로 노출.
- 다크모드: `.dark` 클래스(또는 `@media (prefers-color-scheme: dark)`)에서 semantic 변수만 재정의. 컴포넌트 클래스 무수정.
- **마이그레이션 주의**: 현재 웹은 `bg-blue-400` 같은 raw Tailwind 클래스를 직접 사용 중. 이를 점진적으로 `bg-primary` 등 semantic 유틸리티로 교체해야 실제 SSOT가 된다(§6, 트레이드오프).

### 5.3 "토큰 하나 추가" 절차 (두 플랫폼 반영)
1. `tokens.json`의 적절한 계층에 토큰 추가(semantic이면 light/dark 둘 다).
2. 생성기 실행 → SwiftUI 상수 파일 + CSS 변수 블록 재생성(커밋).
3. 필요 시 `component.*`에 컴포넌트 토큰 추가 후 다시 생성.
4. 컴포넌트가 새 semantic/component 토큰을 참조하도록 연결.
→ 피처 코드는 손대지 않는다.

### 5.4 향후 SSR / 서버주도 테마 확장 지점
- semantic 매핑(어떤 primitive를 primary로 쓸지)을 **런타임 payload**로 서버가 내려줄 수 있게 설계.
- 웹 SSR: 서버가 요청별 테마 JSON을 받아 `:root` 인라인 스타일(CSS 변수)로 렌더 → 클라 하이드레이션 전에 색 확정(FOUC 없음).
- iOS: `Theme`를 서버 payload로 초기화 → `@Environment(\.theme)` 교체. 컴포넌트 무수정으로 리브랜딩/파트너 화이트라벨 가능.
- 이때도 **컴포넌트는 semantic/component 토큰만 참조**하므로 매핑 교체만으로 전면 적용된다.

---

## 6. 사용 규칙 (피처 코드)

1. **raw 값 금지**: 피처/화면 코드에서 hex, `16`, `Color.blue`, `.padding(20)`, `bg-blue-400` 같은 **날 값 사용 금지**. 반드시 semantic/component 토큰 경유.
2. **primitive 직접 참조 금지**: 피처는 semantic 이상만. primitive는 semantic 정의부에서만.
3. **컴포넌트 우선**: 버튼·카드 등은 반드시 DesignSystem 컴포넌트로 조립. 새 UI는 기존 컴포넌트 조합으로 만든다(목표 3).
4. **없으면 추가**: 필요한 토큰/컴포넌트가 없으면 임의 값 대신 DesignSystem에 토큰/변형을 추가한 뒤 사용.
5. **위반 방지 관례**:
   - iOS: `Color(hex:)`·`.font(.system(size:))`·매직 숫자 패딩을 **lint 룰/리뷰 체크**로 차단. 원시 색 이니셜라이저는 `Tokens/` 내부에서만 허용(접근제어 `internal`).
   - 웹: raw Tailwind 색 클래스(`bg-blue-*` 등)를 ESLint(`no-restricted-syntax`) 또는 Tailwind safelist 축소로 경고 → semantic 유틸리티만 허용.
   - PR 템플릿에 "새 색/간격 추가 시 tokens.json 경유했는가?" 체크박스.

---

## 7. 도메인 색 레퍼런스 (한눈에)

| 기록 | 토큰 | 라이트 값 |
|---|---|---|
| 분유 | `domain.feeding.formula` | blue-500 |
| 모유 좌 | `domain.feeding.breastLeft` | pink-400 |
| 모유 우 | `domain.feeding.breastRight` | pink-500 |
| 모유 양쪽 | `domain.feeding.breastBoth` | purple-400 |
| 이유식 | `domain.feeding.solids` | brown-600 |
| 소변 | `domain.diaper.pee` | cyan-400 |
| 대변 | `domain.diaper.poop` | yellow-500 |
| 둘 다 | `domain.diaper.both` | orange-400 |
| 수면 | `domain.sleep` | purple-400 |
| 놀이 | `domain.play` | green-400 |
| 변색: 노랑/녹/갈 | `domain.stool.{yellow,green,brown}` | 정상 |
| 변색: 검정 | `domain.stool.black` | 주의 |
| 변색: 빨강/흰 | `domain.stool.{red,white}` | 경고(white는 테두리 필수) |

---

## 8. 트레이드오프 / 미결정 (리뷰 논의)

1. **모유 좌/우 색 구분**: 웹은 좌·우 모두 pink-400(도트 동일). 좌우 식별을 위해 우측을 pink-500으로 승격 제안 — 실제 UX상 좌우 구분이 필요한지 확인 필요(현재 라벨로 구분 중).
2. **breastBoth**: iOS는 orange, 웹은 pink. 여기선 purple-400로 통일 제안(기저귀 both의 orange와 충돌 회피). 확정 필요.
3. **다크모드 도메인 tint**: 다크에서 tint를 진한 색조(예: blue-700)로 뒀으나, 실제 대비 검증 필요(자동 대비 테스트 도입 권장).
4. **생성기 형태**: Style Dictionary 도입 vs 자체 경량 스크립트. 의존성 최소 선호(User Profile)면 Node 경량 스크립트 1개로 두 산출물 생성 권장 — 확정 필요.
5. **웹 마이그레이션 범위**: 현 웹의 raw Tailwind 클래스를 semantic 유틸리티로 전환하는 것은 별도 작업. 신규 iOS는 처음부터 토큰 기반으로 가고, 웹은 점진 전환 권장.
6. **Dynamic Type 상한**: `display`(큰 숫자)는 접근성 초대형에서 레이아웃 깨질 수 있어 상한(`.xxLarge`) 지정 제안.
