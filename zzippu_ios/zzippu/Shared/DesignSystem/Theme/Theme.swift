// Shared/DesignSystem/Theme/Theme.swift
// Theme 구조체 — 컴포넌트/피처가 @Environment(\.theme) 으로 참조하는 단일 진입점.
// 모든 색·타이포·간격·라운드·그림자·모션을 담는다.

import SwiftUI

// MARK: - ThemeColor

struct ThemeColor {
    // MARK: Surface
    let background:      DynamicColor
    let surface:         DynamicColor
    let surfaceElevated: DynamicColor
    let surfaceSunken:   DynamicColor

    // MARK: Primary
    let primary:           DynamicColor
    let primaryPressed:    DynamicColor
    let onPrimary:         DynamicColor
    let primaryTint:       DynamicColor
    let primaryDisabledBg: DynamicColor
    let onPrimaryDisabled: DynamicColor

    // MARK: Text
    let textPrimary:   DynamicColor
    let textStrong:    DynamicColor   // 본문보다 진한 보조 텍스트(gray-700) — 헤더 날짜 등
    let textSecondary: DynamicColor
    let textTertiary:  DynamicColor

    // MARK: Border / Divider
    let border:       DynamicColor
    let borderStrong: DynamicColor
    let cardBorder:   DynamicColor  // 라이트=투명(그림자로 부양), 다크=얇은 border
    let divider:      DynamicColor
    let scrim:        DynamicColor

    // MARK: Status
    let statusSuccessFg:    DynamicColor
    let statusSuccessBg:    DynamicColor
    let statusSuccessSolid: DynamicColor
    let statusWarningFg:    DynamicColor
    let statusWarningBg:    DynamicColor
    let statusWarningSolid: DynamicColor
    let statusDangerFg:     DynamicColor
    let statusDangerBg:     DynamicColor
    let statusDangerSolid:  DynamicColor
    let statusInfoFg:       DynamicColor
    let statusInfoBg:       DynamicColor
    let statusInfoSolid:    DynamicColor

    // MARK: Domain — Feeding
    let domainFeedingFormulaSolid:    DynamicColor
    let domainFeedingFormulaTint:     DynamicColor
    let domainFeedingBreastLeftSolid: DynamicColor
    let domainFeedingBreastLeftTint:  DynamicColor
    let domainFeedingBreastRightSolid:DynamicColor
    let domainFeedingBreastRightTint: DynamicColor
    let domainFeedingBreastBothSolid: DynamicColor
    let domainFeedingBreastBothTint:  DynamicColor
    let domainFeedingSolidsSolid:     DynamicColor
    let domainFeedingSolidsTint:      DynamicColor

    // MARK: Domain — Diaper
    let domainDiaperPeeSolid:  DynamicColor
    let domainDiaperPeeTint:   DynamicColor
    let domainDiaperPoopSolid: DynamicColor
    let domainDiaperPoopTint:  DynamicColor
    let domainDiaperBothSolid: DynamicColor
    let domainDiaperBothTint:  DynamicColor

    // MARK: Domain — Stool swatches
    let domainStoolYellow: DynamicColor
    let domainStoolGreen:  DynamicColor
    let domainStoolBrown:  DynamicColor
    let domainStoolBlack:  DynamicColor
    let domainStoolRed:    DynamicColor
    let domainStoolWhite:  DynamicColor

    // MARK: Domain — Sleep / Play
    let domainSleepSolid: DynamicColor
    let domainSleepTint:  DynamicColor
    let domainPlaySolid:  DynamicColor
    let domainPlayTint:   DynamicColor

    // MARK: Domain — Checkup (영유아 검진 달력 표시 전용)
    let domainCheckupSolid: DynamicColor
    let domainCheckupTint:  DynamicColor
    /// 검진 차수별 색상(1~8차). 차수마다 시각 구분되도록 서로 다른 색.
    let domainCheckupPalette: [DynamicColor]

    // MARK: QuickButton — 홈 6버튼 상태별 팔레트(웹 BigActionGrid 1:1)
    let quickButton: (QuickButtonKind) -> QuickButtonColors

    // MARK: Domain color lookup (저결합)
    func solid(for kind: DomainKind) -> DynamicColor {
        switch kind {
        case .feedingFormula:     return domainFeedingFormulaSolid
        case .feedingBreastLeft:  return domainFeedingBreastLeftSolid
        case .feedingBreastRight: return domainFeedingBreastRightSolid
        case .feedingBreastBoth:  return domainFeedingBreastBothSolid
        case .feedingSolids:      return domainFeedingSolidsSolid
        case .diaperPee:          return domainDiaperPeeSolid
        case .diaperPoop:         return domainDiaperPoopSolid
        case .diaperBoth:         return domainDiaperBothSolid
        case .sleep:              return domainSleepSolid
        case .play:               return domainPlaySolid
        case .careBath:           return DynamicColor(light: PrimitiveColor.blue500, dark: PrimitiveColor.blue400)
        case .careSupplement:     return DynamicColor(light: PrimitiveColor.teal500, dark: PrimitiveColor.teal400)
        case .careMedicine:       return DynamicColor(light: PrimitiveColor.red500,  dark: PrimitiveColor.red400)
        case .careHospital:       return DynamicColor(light: PrimitiveColor.purple500, dark: PrimitiveColor.purple400)
        case .careWalk:           return DynamicColor(light: PrimitiveColor.green500, dark: PrimitiveColor.green400)
        case .checkup:            return domainCheckupSolid
        }
    }

    func tint(for kind: DomainKind) -> DynamicColor {
        switch kind {
        case .feedingFormula:     return domainFeedingFormulaTint
        case .feedingBreastLeft:  return domainFeedingBreastLeftTint
        case .feedingBreastRight: return domainFeedingBreastRightTint
        case .feedingBreastBoth:  return domainFeedingBreastBothTint
        case .feedingSolids:      return domainFeedingSolidsTint
        case .diaperPee:          return domainDiaperPeeTint
        case .diaperPoop:         return domainDiaperPoopTint
        case .diaperBoth:         return domainDiaperBothTint
        case .sleep:              return domainSleepTint
        case .play:               return domainPlayTint
        case .careBath:           return DynamicColor(light: PrimitiveColor.blue50, dark: PrimitiveColor.blue500.opacity(0.18))
        case .careSupplement:     return DynamicColor(light: PrimitiveColor.teal50, dark: PrimitiveColor.teal500.opacity(0.18))
        case .careMedicine:       return DynamicColor(light: PrimitiveColor.red50,  dark: PrimitiveColor.red500.opacity(0.18))
        case .careHospital:       return DynamicColor(light: PrimitiveColor.purple50, dark: PrimitiveColor.purple500.opacity(0.18))
        case .careWalk:           return DynamicColor(light: PrimitiveColor.green50, dark: PrimitiveColor.green500.opacity(0.18))
        case .checkup:            return domainCheckupTint
        }
    }

    /// 검진 차수(1~8) → 팔레트 색. 범위 밖은 순환. 팔레트 비면 기본색.
    func checkupColor(round: Int) -> DynamicColor {
        guard !domainCheckupPalette.isEmpty else { return domainCheckupSolid }
        let idx = (max(1, round) - 1) % domainCheckupPalette.count
        return domainCheckupPalette[idx]
    }

    func swatch(for stool: StoolSwatch) -> DynamicColor {
        switch stool {
        case .yellow: return domainStoolYellow
        case .green:  return domainStoolGreen
        case .brown:  return domainStoolBrown
        case .black:  return domainStoolBlack
        case .red:    return domainStoolRed
        case .white:  return domainStoolWhite
        }
    }

    func status(tone: StatusTone) -> (fg: DynamicColor, bg: DynamicColor, solid: DynamicColor) {
        switch tone {
        case .success: return (statusSuccessFg, statusSuccessBg, statusSuccessSolid)
        case .warning: return (statusWarningFg, statusWarningBg, statusWarningSolid)
        case .danger:  return (statusDangerFg,  statusDangerBg,  statusDangerSolid)
        case .info:    return (statusInfoFg,    statusInfoBg,    statusInfoSolid)
        }
    }
}

// MARK: - ThemeTypography

struct ThemeTypography {
    let display:      Font  // tabular large numbers, capped Dynamic Type
    let title:        Font
    let headline:     Font
    let headlineStrong: Font  // 16pt/bold — 헤더 아기이름(R4)
    let body:         Font
    let bodyStrong:   Font
    let callout:      Font
    let caption:      Font
    let captionStrong:Font
    let label:        Font
    let mono:         Font  // monospaced, capped Dynamic Type
    let input:        Font  // 16pt 고정 — iOS 자동줌 방지(회귀 방지선)
}

// MARK: - ThemeSpace

struct ThemeSpace {
    /// 컴포넌트 수평 내부 패딩 (16pt)
    let componentPaddingX: CGFloat
    /// 컴포넌트 수직 내부 패딩 (12pt)
    let componentPaddingY: CGFloat
    /// 카드 패딩 (20pt)
    let cardPadding:       CGFloat
    /// 화면 좌우 패딩 (16pt)
    let screenPaddingX:    CGFloat
    /// 화면 상하 패딩 (16pt)
    let screenPaddingY:    CGFloat
    /// 섹션 간격 (16pt)
    let sectionGap:        CGFloat
    /// 스택 소형 gap (8pt)
    let stackGapSm:        CGFloat
    /// 스택 중형 gap (12pt)
    let stackGapMd:        CGFloat
    /// 인라인 gap (8pt)
    let inlineGap:         CGFloat

    // Primitive shortcuts (컴포넌트 내부용)
    let xs: CGFloat   // 4
    let sm: CGFloat   // 8
    let md: CGFloat   // 16
    let lg: CGFloat   // 24
    let xl: CGFloat   // 32
}

// MARK: - ThemeRadius

struct ThemeRadius {
    let control:   CGFloat  // 12  (44pt 컨트롤)
    let controlLg: CGFloat  // 16  (56pt 대형 버튼·BigActionButton)
    let card:      CGFloat  // 16
    let sheet:     CGFloat  // 24
    let pill:      CGFloat  // 9999
}

// MARK: - ThemeShadow

struct ThemeShadow {
    let sm: DSShadowStyle
    let md: DSShadowStyle
    let lg: DSShadowStyle
    let xl: DSShadowStyle
}

// MARK: - ThemeMotion

struct ThemeMotion {
    let fast:             Double
    let normal:           Double
    let slow:             Double
    let toastAutoDismiss: Double
    let spring:           Animation
    let springFast:       Animation
}

// MARK: - ComponentTokens

struct ComponentButtonTokens {
    let heightSm:      CGFloat
    let heightMd:      CGFloat
    let heightLg:      CGFloat
    let minWidth:      CGFloat
    let paddingXMd:    CGFloat
    let radius:        CGFloat  // 12 (sm/md)
    let radiusLg:      CGFloat  // 16 (lg — 56pt)
    let disabledOpacity: Double
}

struct ComponentCardTokens {
    let padding: CGFloat
    let radius:  CGFloat
    let shadow:  DSShadowStyle
}

struct ComponentInputTokens {
    let height:   CGFloat
    let paddingX: CGFloat
    let radius:   CGFloat
}

struct ComponentChipTokens {
    let paddingX: CGFloat
    let height:   CGFloat
    let radius:   CGFloat
}

struct ComponentCalendarCellTokens {
    let minHeight:      CGFloat  // 52
    let spacing:        CGFloat  // 4  (셀 간격)
    let todayCircle:    CGFloat  // 24 (오늘 강조 원 지름)
    let underbarHeight: CGFloat  // 3
    let eventDotSize:   CGFloat  // 6
}

struct ComponentTokens {
    let button:     ComponentButtonTokens
    let card:       ComponentCardTokens
    let input:      ComponentInputTokens
    let chip:       ComponentChipTokens
    let iconButtonSize: CGFloat
    let emptyStatePaddingY: CGFloat
    let sectionHeaderPaddingY: CGFloat
    let statusPillPaddingX: CGFloat  // 12
    let statusPillPaddingY: CGFloat  // 6
    let timelineDotSize:     CGFloat // 10
    let timelineDotSizeIdle: CGFloat // 8
    let calendarCell:        ComponentCalendarCellTokens
}

// MARK: - Theme

struct Theme {
    let color:      ThemeColor
    let typography: ThemeTypography
    let space:      ThemeSpace
    let radius:     ThemeRadius
    let shadow:     ThemeShadow
    let motion:     ThemeMotion
    let component:  ComponentTokens
}

// MARK: - Domain Kind (DesignSystem-internal, domain 비의존)

/// DesignSystem 내부 키. 도메인 엔티티에 의존하지 않음.
/// 피처가 자신의 도메인 타입 → DomainKind 로 변환해 Theme.color.solid(for:) 를 호출한다.
public enum DomainKind {
    case feedingFormula
    case feedingBreastLeft
    case feedingBreastRight
    case feedingBreastBoth
    case feedingSolids
    case diaperPee
    case diaperPoop
    case diaperBoth
    case sleep
    case play
    case careBath        // 목욕
    case careSupplement  // 영양제
    case careMedicine    // 약
    case careHospital    // 병원
    case careWalk        // 산책
    case checkup  // 영유아 검진 달력 표시
}

/// 홈 퀵버튼(BigActionGrid) 도메인 키.
/// rawValue = 저장 ID (변경 금지 — UserDefaults 직렬화 키로 사용됨).
public enum QuickButtonKind: String, CaseIterable {
    case formula     = "formula"
    case breast      = "breast"
    case pee         = "pee"
    case poo         = "poo"
    case sleep       = "sleep"
    case play        = "play"
    case supplement  = "supplement"
    case medicine    = "medicine"
    case bath        = "bath"
    case hospital    = "hospital"
    case walk        = "walk"
}

/// 퀵버튼 상태별 색 묶음(idle/active × bg/border/text). 웹 BigActionGrid 상태 매핑.
/// DynamicColor(internal)를 담으므로 struct도 internal 유지(ThemeColor와 동일 접근수준).
struct QuickButtonColors {
    let idleBg:       DynamicColor
    let idleBorder:   DynamicColor
    let idleText:     DynamicColor
    let activeBg:     DynamicColor
    let activeBorder: DynamicColor
    let activeText:   DynamicColor
}

/// 대변 색 스와치 키
public enum StoolSwatch {
    case yellow, green, brown, black, red, white
}

/// 상태 톤 키
public enum StatusTone {
    case success, warning, danger, info
}
