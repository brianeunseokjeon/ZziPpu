# 컴포넌트 카탈로그 + 확장 API

> `tokens.json`·`DESIGN_SYSTEM.md`를 전제로 한다. 각 컴포넌트의 **변형(variant)·크기(size)·상태(state)**, 사용 토큰, **SwiftUI 관용 확장 API**, 웹 대응 매핑을 정의한다.
> 핵심 원칙: **변형 추가 시 기존 컴포넌트 코드를 수정하지 않는다**(Open-Closed). SwiftUI는 `ButtonStyle`/`LabelStyle` 프로토콜·`ViewModifier`·조합형 View로 확장한다.

---

## 0. 테마 주입 메커니즘 (모든 컴포넌트의 기반)

컴포넌트는 색·간격을 하드코딩하지 않고 **주입된 `Theme`**를 읽는다. 라이트/다크/리브랜딩/서버주도 테마 교체가 컴포넌트 수정 없이 가능해진다.

```swift
// Shared/DesignSystem/Theme/Theme.swift (개념)
struct Theme {
    let color: ThemeColor       // semantic 색 (DynamicColor: light/dark 내장)
    let typography: ThemeTypography
    let space: ThemeSpace
    let radius: ThemeRadius
    let shadow: ThemeShadow
    let motion: ThemeMotion
    let component: ComponentTokens  // component.* 계층
}

private struct ThemeKey: EnvironmentKey { static let defaultValue = Theme.zzippu }
extension EnvironmentValues { var theme: Theme { get { self[ThemeKey.self] } set { self[ThemeKey.self] = newValue } } }

// 앱 루트에서 주입:
//   RootView().environment(\.theme, .zzippu)
// 서버주도/리브랜딩:
//   RootView().environment(\.theme, Theme(from: serverPayload))
```

- 컴포넌트 내부: `@Environment(\.theme) private var theme`.
- `DynamicColor`가 light/dark를 내장하므로 시스템 다크모드는 자동. 강제 테마 교체는 `\.theme` 자체를 바꾸면 됨.
- **배치**: `ARCHITECTURE_DESIGN_SYSTEM.md`의 `Shared/DesignSystem/Theme/`. 도메인/피처 비의존.

---

## 1. Button

| 축 | 값 |
|---|---|
| variant | `primary` / `secondary` / `tertiary` / `destructive` |
| size | `sm`(36) / `md`(44) / `lg`(56) |
| state | `normal` / `pressed` / `disabled` / `loading` |

- 토큰: `component.button.*`. primary=`primary/onPrimary`, destructive=`status.danger.solid`.
- loading: 라벨 자리에 `ProgressView`, 터치 비활성, opacity 유지(레이아웃 점프 방지).
- 항상 `minWidth 44`·높이 토큰 준수(터치타깃).

**SwiftUI 확장 API — `ButtonStyle` 프로토콜로 변형 확장**
```swift
struct DSButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, tertiary, destructive }
    enum Size { case sm, md, lg }
    let variant: Variant; let size: Size; var isLoading = false
    @Environment(\.theme) var theme
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Configuration) -> some View { /* theme 토큰으로 렌더, configuration.isPressed로 pressed */ }
}
extension ButtonStyle where Self == DSButtonStyle {
    static func ds(_ v: DSButtonStyle.Variant, size: DSButtonStyle.Size = .md, loading: Bool = false) -> DSButtonStyle { .init(variant: v, size: size, isLoading: loading) }
}
// 사용: Button("저장") { }.buttonStyle(.ds(.primary))
// 새 변형 추가: Variant에 case 추가 or 별도 ButtonStyle 신규 — 기존 사용처 무영향.
```
- 웹 매핑: `button.tsx` `buttonVariants`(cva)의 variant/size. primary=default, tertiary=outline/ghost.

## 2. Surface / Card

- variant: `plain`(테두리+shadow-sm) / `sunken`(surfaceSunken, 그림자 없음) / `interactive`(탭 시 press 피드백).
- 토큰: `component.card.*`. slot: header/title/description/content/footer(웹 card.tsx 구조 대응).
- SwiftUI: `CardContainer<Content: View>` 조합형 View + `.dsCard()` `ViewModifier`. 변형은 `style:` 파라미터로.
- 웹 매핑: `Card/CardHeader/CardContent/...`.

## 3. TextField / Input

- variant: `default` / `error`(border=danger.solid) / `focused`(border=primary).
- state: normal/focused/error/disabled. size: md 고정(44, 최소 16pt 폰트로 iOS 자동줌 방지).
- 토큰: `component.input.*`. 부속: 라벨·헬퍼/에러 텍스트(caption).
- SwiftUI: `DSTextField` View + `.dsFieldStyle(state:)` modifier. TimeField/NumberStepper는 별도 컴포넌트가 감싼다.
- 웹 매핑: `input.tsx`, `time-field.tsx`.

## 4. Chip / Tag / QuickChips

- variant: `selectable`(선택 토글) / `static`(태그) / `quick`(빠른 입력 프리셋).
- state: selected/idle/disabled. 토큰: `component.chip.*`(선택 시 primaryTint). 높이 44(오탭 방지).
- SwiftUI: `DSChip(label:isSelected:)` + `QuickChipsRow` 조합형(수유량 100/120/150 프리셋 등). 도메인 색 칩은 `tint:` 주입.
- 웹 매핑: FeedingForm의 side/mode 토글 버튼군.

## 5. StatusPill / Badge

- **StatusPill**(상태): variant=`success/warning/danger/info`. 토큰 `component.statusPill.*` + `status.{tone}.{bg,fg}`. 텍스트 병기 필수(색만으로 X). 예: "적정"(success), "권장보다 적음"(warning).
- **Badge**(도메인 태그): variant=`feeding/sleep/diaper/play`. `component.badge.*` + `domain.*.{tint,solid}`.
- SwiftUI: `DSStatusPill(tone:text:)`, `DSBadge(domain:text:)`. tone/domain은 enum → 새 도메인 추가만으로 확장.
- 웹 매핑: FeedingAdequacyCard의 `meta.tone` pill, `badge.tsx` variants.

## 6. ListRow

- variant: `plain` / `navigable`(chevron) / `withTrailing`(우측 액션). state: pressed/selected.
- 토큰: `component.listRow.*`(minHeight 44, divider). leading(아이콘/도트)·title·subtitle·trailing 슬롯.
- SwiftUI: `DSListRow { leading } content: { } trailing: { }` 조합형. 구분선은 `divider` 토큰.

## 7. TimelineRow (도트·색)

- DayTimeline 한 행. dot 색 = `domain.*.solid` 주입. variant: `normal` / `highlighted`(최신 그룹, highlightBg + 좌측 highlightBar).
- 토큰: `component.timelineRow.*`(도트 6/8, mono 시각, primaryTint 강조).
- 구성: `[mono 시각]  ● [라벨]  [편집 아이콘버튼]`. 1분 단위 그룹핑은 피처 로직(컴포넌트는 표현만).
- SwiftUI: `TimelineGroupView`(시각+items) + `TimelineItemRow(dotColor:label:)`. 도메인→도트색 매핑은 semantic 토큰 룩업.
- 웹 매핑: `DayTimeline.tsx`(DOTS 맵 → domain 토큰으로 승격).

## 8. SectionHeader

- variant: `plain` / `withAction`(우측 링크). 토큰 `component.sectionHeader.*`(captionStrong, textSecondary).
- SwiftUI: `DSSectionHeader(title:action:)`.

## 9. EmptyState

- 아이콘/이모지 + 메시지(+옵션 CTA). 토큰 `component.emptyState.*`(textTertiary, 세로 여백).
- SwiftUI: `DSEmptyState(icon:message:action:)`. 예: "이 날의 기록이 없어요".

## 10. BottomSheet

- variant: `default` / `fullHeight`. state: presented/dismissing. 스크림 탭·드래그 다운으로 닫힘.
- 토큰: `component.bottomSheet.*`(radius xl, scrim 0.4, shadow xl, grabber). safe-area 하단 확보.
- SwiftUI: `.dsBottomSheet(isPresented:) { }` modifier(내부 `presentationDetents`·커스텀 스크림). 헤더(타이틀+닫기)는 옵션.
- 웹 매핑: `dialog.tsx`(portal 바텀시트).

## 11. IconButton

- variant: `plain` / `tinted`. size: md(44). 토큰 `component.iconButton.*`. pressed 시 primary.
- SwiftUI: `DSIconButton(systemName:action:)`. 44 터치타깃 강제.
- 웹 매핑: 헤더 날짜 네비 버튼, 타임라인 편집 버튼, 토스트 닫기.

## 12. Avatar (아기)

- variant: `photo` / `fallback`(성별 그라데이션 + 👶). size: sm(32, 헤더) / lg(80, 프로필). 원형.
- 토큰: `component.avatar.*`(성별 그라데이션). 사진 로드 실패 시 fallback(웹 BabyAvatar 로직 동일).
- SwiftUI: `BabyAvatar(photoURL:gender:size:)`. AsyncImage 실패 → fallback View.

## 13. GaugeBar (수유량)

- variant: 상태 채움(`success/warning/danger`) — fill 색 주입. 부속: normalBand(권장 구간 오버레이).
- 토큰: `component.gaugeBar.*`(track=sunken, normalBand=success.bg, height 12, pill). 초과분도 보이게 스케일(피처 로직).
- SwiftUI: `DSGaugeBar(fillRatio:normalRange:tone:)`. tone→fill 색은 `status.{tone}.solid`.
- 웹 매핑: FeedingAdequacyCard 게이지.

## 13a. DonutChart (비중)

- variant: 2~4 세그먼트 비중 도넛. `size` = `sm`(카드 미니, 라벨 숨김) / `lg`(상세, 범례). 데이터 없으면 완곡한 빈 링 + 중앙 "—".
- 토큰: 세그먼트 색은 호출자가 `domain*Solid`/`status*` Color로 주입(DS는 Domain 비의존). 빈 링=`surfaceSunken`, 중앙 텍스트=`textPrimary`.
- SwiftUI: `DSDonutChart(segments:[DSDonutSegment(value:color:label:)], centerText:centerCaption:size:showLegend:)`. Swift Charts `SectorMark`(iOS17+, innerRadius ratio 0.62).
- 웹 매핑: 대시보드 수유(분유:모유) / 기저귀(소:대) 비중 원그래프.

## 13b. RingGauge (적정도)

- variant: 단일 진행/적정도 링(270° 아크). `tone`→채움색, `normalRange`(권장 상한 기준 정규화)로 권장 밴드 강조. 중앙 대표값(display36).
- 토큰: track=`surfaceSunken`, normalBand=`status.success.bg`, fill=`status.{tone}.solid`. 내부 130% 축으로 초과분 표시.
- SwiftUI: `DSRingGauge(ratio:normalRange:tone:centerText:centerCaption:size:lineWidth:)`. `ratio`=총량/권장상한. `Path` 아크(Shape) 구현.
- 웹 매핑: FeedingAdequacyCard 대표 지표(오늘 수유량 링).

## 14. Toast / Snackbar

- variant: `success` / `error` / `info`. 하단 중앙, 자동 소멸(3.5s, `motion.toastAutoDismissMs`), 탭 시 즉시 닫힘.
- 토큰: `component.toast.*` + `status.{tone}.{bg,fg}`(info는 gray-800/white 유지). slideUp(fast) 진입.
- SwiftUI: 전역 `ToastCenter`(Observable) + 루트 오버레이 `ToastHost`. `theme.motion` 존중, reduceMotion 시 페이드.
- 웹 매핑: `Toaster.tsx`.

## 15. TabBarItem

- state: active(primary, stroke 2.5) / inactive(textTertiary). 아이콘+라벨(label typography). itemMinHeight 56.
- 토큰: `component.tabBar.*`. safe-area 하단 패딩.
- SwiftUI: `DSTabBar(items:selection:)` + `DSTabItem`. 웹 매핑: `BottomTabBar.tsx`.

## 16. AppHeader

- 구성: `[아바타][이름/나이]  ······  [< 날짜 >]`. sticky, safe-area 상단. 날짜 네비(어제/오늘/다음, 오늘이면 다음 비활성).
- 토큰: `component.appHeader.*`(height 56, avatar 32, titleTypography=bodyStrong, subtitle=caption).
- SwiftUI: `AppHeader(baby:selectedDate:onDateChange:)` 조합(BabyAvatar + IconButton 재사용).
- 웹 매핑: `layout/Header.tsx`.

## 17. NumberStepper (빠른 입력)

- 구성: `[−] [값] [+]` + 직접입력. 범위 clamp(예: 분유 0~500), step 주입. 버튼 44.
- 토큰: `component.numberStepper.*`(value=title typography). QuickChips와 조합해 프리셋 제공.
- SwiftUI: `DSNumberStepper(value:range:step:)`. 웹 매핑: FeedingForm의 `adjustAmount`(Minus/Plus).

---

## 18. 확장 패턴 요약 (Open-Closed)

| 확장 종류 | 방법 | 기존 코드 영향 |
|---|---|---|
| 버튼/라벨 새 변형 | `ButtonStyle`/`LabelStyle` 준수 타입 추가 or enum case 추가 | 없음 |
| 컴포넌트 스타일 변형 | `style:`/`variant:` enum 파라미터 확장 | 없음 |
| 횡단 표현(그림자·패딩) | `ViewModifier` + `View` 확장 헬퍼 | 없음 |
| 새 도메인 색 | tokens.json `domain.*` 추가 → 생성 → enum case | 없음(룩업) |
| 리브랜딩/서버테마 | `\.theme` 환경값 교체 | 없음 |

---

## 19. 컴포넌트 → 토큰 매핑 인덱스

| 컴포넌트 | 주 토큰 그룹 |
|---|---|
| Button | `component.button`, `color.primary/onPrimary/status.danger` |
| Card | `component.card`, `color.surface/border`, `shadow.sm` |
| Input | `component.input`, `color.surface/borderStrong/primary` |
| Chip | `component.chip`, `color.primaryTint`, `domain.*` |
| StatusPill | `component.statusPill`, `color.status.*` |
| Badge | `component.badge`, `color.domain.*` |
| TimelineRow | `component.timelineRow`, `color.domain.*.solid`, `typography.mono` |
| GaugeBar | `component.gaugeBar`, `color.status.*`, `surfaceSunken` |
| Toast | `component.toast`, `color.status.*`, `motion` |
| TabBar | `component.tabBar`, `color.primary/textTertiary` |
| AppHeader | `component.appHeader`, `avatar`, `iconButton` |
| BottomSheet | `component.bottomSheet`, `color.scrim`, `shadow.xl` |

---

## 20. 미결정 (리뷰 논의)
- **DSButtonStyle vs 커스텀 View**: loading 상태를 ButtonStyle로 표현할지, `DSButton` 래퍼 View로 감쌀지(ButtonStyle은 configuration.label 교체가 제한적). 래퍼 View + 내부 ButtonStyle 조합 권장.
- **BottomSheet 구현체**: iOS16 `presentationDetents` vs 자체 오버레이(웹 dialog처럼 완전 커스텀). 커스텀 스크림/코너가 필요하면 후자.
- **Toast 중복/큐잉 정책**: 동시 다수 토스트 스택 vs 단일 교체 — 웹은 스택. 신생아 UX상 단일+교체가 덜 산만할 수 있음.
