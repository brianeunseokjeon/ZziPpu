# DesignSystem 클린아키텍처 배치

> DesignSystem을 도메인/피처에 **의존하지 않는 독립 Shared 모듈**로 배치한다. 저결합·고응집·확장 용이. 향후 SPM 모듈 분리 대비.

---

## 1. 폴더 구조 (iOS)

```
zzippu/Shared/DesignSystem/
├── Tokens/          # tokens.json에서 "생성"된 원시/역할 상수 (손수정 금지)
│   ├── PrimitiveColors.generated.swift
│   ├── PrimitiveScale.generated.swift      # space/radius/size
│   ├── SemanticColors.generated.swift      # DynamicColor(light/dark)
│   ├── Typography.generated.swift
│   ├── Shadows.generated.swift
│   └── Motion.generated.swift
├── Theme/           # 테마 구조체 + 주입 메커니즘
│   ├── Theme.swift              # Theme, ThemeColor/Typography/... 구조체
│   ├── Theme+zzippu.swift       # 기본 테마 조립(생성 토큰 → Theme)
│   ├── DynamicColor.swift       # light/dark → SwiftUI Color 해석
│   └── EnvironmentTheme.swift   # @Environment(\.theme) 키
├── Foundation/      # 토큰 위의 얇은 헬퍼(도메인 무관)
│   ├── Color+Hex.swift
│   ├── View+DSShadow.swift
│   ├── View+DSCard.swift
│   └── DomainColorMap.swift     # FeedingType/DiaperType/StoolColor → semantic 토큰
└── Components/      # 재사용 UI 컴포넌트 (COMPONENTS.md)
    ├── Buttons/ (DSButtonStyle, DSIconButton)
    ├── Containers/ (CardContainer, DSBottomSheet)
    ├── Inputs/ (DSTextField, DSNumberStepper, DSChip)
    ├── Feedback/ (DSStatusPill, DSBadge, ToastHost, DSGaugeBar)
    ├── Lists/ (DSListRow, TimelineItemRow, DSSectionHeader, DSEmptyState)
    └── Navigation/ (DSTabBar, AppHeader, BabyAvatar)
```

- **`.generated.swift`**: `tokens.json` → 생성기 산출물. 손으로 고치지 않는다(고치면 원천과 어긋남). 생성기 실행 후 커밋.
- **`DomainColorMap`**: 도메인 *enum 타입*(FeedingType 등)을 인자로 받아 semantic 토큰을 돌려주는 순수 함수. **주의**: enum 자체가 도메인에 정의돼 있으면 의존 역전이 생기므로, DesignSystem은 도메인을 import하지 않고 **문자열 키**(`"formula"` 등) 또는 DesignSystem 내부 `DomainKind` enum을 받는다(§3).

---

## 2. 의존성 규칙

```
Features ──▶ DesignSystem ──▶ (SwiftUI only)
Domain   ──▶ (없음)
DesignSystem ─╳▶ Domain / Features   (금지)
```

- **DesignSystem은 도메인/피처를 모른다.** import 하지 않는다. 오직 SwiftUI/Foundation만.
- **피처가 DesignSystem을 사용한다**: 컴포넌트 조립·토큰 참조는 피처→DesignSystem 단방향.
- 도메인 색이 필요한 지점(수유/기저귀 색): DesignSystem은 **플랫폼 중립 키**(`DomainKind.feedingFormula` 같은 자체 enum, 또는 raw string)만 안다. 피처가 자신의 도메인 타입 → DesignSystem 키로 변환해 넘긴다. → DesignSystem은 여전히 도메인 비의존.

**고응집 근거**: 색·타이포·컴포넌트가 한 모듈에 모여 변경 파급이 국소화. **저결합 근거**: 피처는 Theme 인터페이스에만 의존, 구현(값) 교체가 자유(다크/리브랜딩/서버테마).

---

## 3. 도메인 색 브릿지 (의존 역전 방지)

```swift
// DesignSystem 내부 — 도메인 비의존 키
public enum DomainKind {
    case feedingFormula, feedingBreastLeft, feedingBreastRight, feedingBreastBoth, feedingSolids
    case diaperPee, diaperPoop, diaperBoth
    case sleep, play
}
public enum StoolSwatch { case yellow, green, brown, black, red, white }

extension Theme {
    func color(for kind: DomainKind) -> Color { /* semantic.domain.* 룩업 */ }
    func swatch(for s: StoolSwatch) -> Color { /* semantic.domain.stool.* */ }
}

// 피처 쪽(도메인 → DS 키 변환은 피처 책임)
extension FeedingType { var dsKind: DomainKind { ... } }   // 피처 모듈에 위치
```
→ DesignSystem은 `FeedingType`을 모른 채 색을 제공. 새 도메인 값은 `DomainKind`에 추가 + tokens.json 확장.

---

## 4. 기존 자산 마이그레이션

현재: `Shared/DesignSystem/{AppColor, AppSpacing, AppTypography}.swift`(최소 상태). 흡수 방식:

| 기존 | 신규 | 방법 |
|---|---|---|
| `AppSpacing.md=16` 등 | `Tokens/PrimitiveScale` + `Theme.space` | 값 정렬됨. `AppSpacing`을 `theme.space`로 대체, 한동안 `AppSpacing`을 신 토큰 별칭으로 `deprecated` 유지 후 제거. |
| `AppTypography.*`(Font) | `Typography.generated` + `Theme.typography` | TextStyle 매핑 유지. `AppTypography` → deprecated alias. |
| `AppColor`(`.blue`/`.pink` 등 raw) | `SemanticColors.generated` + `Theme.color` | raw 시스템 색을 semantic/domain 토큰으로 치환. `formula=.blue` → `domain.feeding.formula`. `AppColor` deprecated alias. |

**단계적 마이그레이션**
1. `tokens.json` 확정 → 생성기로 `Tokens/*.generated.swift` 생성.
2. `Theme` + `@Environment(\.theme)` 도입, 앱 루트에서 주입.
3. 기존 `AppColor/Spacing/Typography`를 새 토큰을 가리키는 `@available(*, deprecated)` 별칭으로 교체(호출부 컴파일 유지).
4. 컴포넌트(`Components/`) 구현 → 피처가 raw 대신 컴포넌트/`theme` 사용하도록 점진 교체.
5. 별칭 제거 → raw 색/숫자 lint 차단 활성화.

---

## 5. SPM 모듈화 대비 (미래)

- `Components/`가 도메인을 import하지 않으므로, DesignSystem 전체를 **별도 SPM 타깃**으로 분리 가능(경계 이미 그어짐).
- 분리 시 public 접근제어만 부여하면 됨. `Tokens/`의 원시 색 이니셜라이저는 `internal`로 캡슐화(피처의 raw 접근 원천 차단).
- 웹/SSR과 공유하는 것은 `tokens.json`(빌드타임 생성 입력)뿐 — 런타임 결합 없음.

---

## 6. 생성 파이프라인 (요약)

```
tokens.json ──(generator)──┬──▶ iOS: Shared/DesignSystem/Tokens/*.generated.swift
                           └──▶ Web: frontend/src/app/tokens.generated.css (@theme 변수)
```
- 생성기: 경량 Node 스크립트 1개 권장(의존 최소). 참조(`{...}`) 해석 + light/dark 전개 + 플랫폼별 포맷.
- CI에서 "생성물이 최신인지" 검증(토큰 수정 후 재생성 누락 방지).

---

## 7. 미결정 (리뷰 논의)
- **생성기 도입 시점**: 초기엔 손으로 `.generated`를 쓰고 나중에 자동화할지 vs 처음부터 스크립트. 토큰 규모상 처음부터 스크립트 권장.
- **접근제어 수준**: 단일 앱 타깃이면 `internal`로 충분. SPM 분리 확정 시 `public` 일괄 부여 필요.
- **DomainKind 위치**: DesignSystem 내부(제안) vs 별도 SharedKit. 도메인 색이 순수 표현 관심사이므로 DesignSystem 내부가 응집도 높음.
