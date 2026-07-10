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
        }
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
    let body:         Font
    let bodyStrong:   Font
    let callout:      Font
    let caption:      Font
    let captionStrong:Font
    let label:        Font
    let mono:         Font  // monospaced, capped Dynamic Type
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
}

/// 대변 색 스와치 키
public enum StoolSwatch {
    case yellow, green, brown, black, red, white
}

/// 상태 톤 키
public enum StatusTone {
    case success, warning, danger, info
}
