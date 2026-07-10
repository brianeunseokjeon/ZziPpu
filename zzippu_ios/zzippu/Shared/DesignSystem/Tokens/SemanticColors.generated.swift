// AUTO-GENERATED — 손대지 말 것
// Source: docs/design-system/tokens.json
// Generator: tools/gen-tokens.mjs  (node tools/gen-tokens.mjs)
// ⚠️  이 파일을 직접 수정하면 토큰 재생성 시 덮어씁니다.

import SwiftUI

// MARK: - Semantic Colors
// DynamicColor wraps a light/dark pair → resolves via system color scheme.
// Feature code references these through Theme.color.*

struct SemanticColorTokens {
    let background: DynamicColor = DynamicColor(light: Color(hex: 0xF9FAFB), dark: Color(hex: 0x111827))
    let surface: DynamicColor = DynamicColor(light: .white, dark: Color(hex: 0x1F2937))
    let surfaceElevated: DynamicColor = DynamicColor(light: .white, dark: Color(hex: 0x374151))
    let surfaceSunken: DynamicColor = DynamicColor(light: Color(hex: 0xF3F4F6), dark: Color(hex: 0x374151))
    let primary: DynamicColor = DynamicColor(light: Color(hex: 0x60A5FA), dark: Color(hex: 0x3B82F6))
    let primaryPressed: DynamicColor = DynamicColor(light: Color(hex: 0x2563EB), dark: Color(hex: 0x1D4ED8))
    let onPrimary: DynamicColor = DynamicColor(light: .white, dark: .white)
    let primaryTint: DynamicColor = DynamicColor(light: Color(hex: 0xEFF6FF), dark: Color(hex: 0x1D4ED8))
    let textPrimary: DynamicColor = DynamicColor(light: Color(hex: 0x111827), dark: Color(hex: 0xF9FAFB))
    let textSecondary: DynamicColor = DynamicColor(light: Color(hex: 0x6B7280), dark: Color(hex: 0x9CA3AF))
    let textTertiary: DynamicColor = DynamicColor(light: Color(hex: 0x9CA3AF), dark: Color(hex: 0x6B7280))
    let border: DynamicColor = DynamicColor(light: Color(hex: 0xF3F4F6), dark: Color(hex: 0x374151))
    let borderStrong: DynamicColor = DynamicColor(light: Color(hex: 0xE5E7EB), dark: Color(hex: 0x4B5563))
    let divider: DynamicColor = DynamicColor(light: Color(hex: 0xF3F4F6), dark: Color(hex: 0x374151))
    let scrim: DynamicColor = DynamicColor(light: .black, dark: .black)
    let statusSuccessFg: DynamicColor = DynamicColor(light: Color(hex: 0x047857), dark: Color(hex: 0x34D399))
    let statusSuccessBg: DynamicColor = DynamicColor(light: Color(hex: 0xD1FAE5), dark: Color(hex: 0x047857))
    let statusSuccessSolid: DynamicColor = DynamicColor(light: Color(hex: 0x34D399), dark: Color(hex: 0x34D399))
    let statusWarningFg: DynamicColor = DynamicColor(light: Color(hex: 0xB45309), dark: Color(hex: 0xFBBF24))
    let statusWarningBg: DynamicColor = DynamicColor(light: Color(hex: 0xFEF3C7), dark: Color(hex: 0xB45309))
    let statusWarningSolid: DynamicColor = DynamicColor(light: Color(hex: 0xFBBF24), dark: Color(hex: 0xFBBF24))
    let statusDangerFg: DynamicColor = DynamicColor(light: Color(hex: 0xBE123C), dark: Color(hex: 0xFB7185))
    let statusDangerBg: DynamicColor = DynamicColor(light: Color(hex: 0xFFE4E6), dark: Color(hex: 0xBE123C))
    let statusDangerSolid: DynamicColor = DynamicColor(light: Color(hex: 0xF87171), dark: Color(hex: 0xF87171))
    let statusInfoFg: DynamicColor = DynamicColor(light: Color(hex: 0x1D4ED8), dark: Color(hex: 0xDBEAFE))
    let statusInfoBg: DynamicColor = DynamicColor(light: Color(hex: 0xDBEAFE), dark: Color(hex: 0x1D4ED8))
    let statusInfoSolid: DynamicColor = DynamicColor(light: Color(hex: 0x3B82F6), dark: Color(hex: 0x3B82F6))
    let domainFeedingFormulaSolid: DynamicColor = DynamicColor(light: Color(hex: 0x3B82F6), dark: Color(hex: 0x60A5FA))
    let domainFeedingFormulaTint: DynamicColor = DynamicColor(light: Color(hex: 0xEFF6FF), dark: Color(hex: 0x3B82F6, opacity: 0.22))
    let domainFeedingBreastLeftSolid: DynamicColor = DynamicColor(light: Color(hex: 0xF472B6), dark: Color(hex: 0xF472B6))
    let domainFeedingBreastLeftTint: DynamicColor = DynamicColor(light: Color(hex: 0xFCE7F3), dark: Color(hex: 0xF472B6, opacity: 0.22))
    let domainFeedingBreastRightSolid: DynamicColor = DynamicColor(light: Color(hex: 0xEC4899), dark: Color(hex: 0xEC4899))
    let domainFeedingBreastRightTint: DynamicColor = DynamicColor(light: Color(hex: 0xFCE7F3), dark: Color(hex: 0xEC4899, opacity: 0.22))
    let domainFeedingBreastBothSolid: DynamicColor = DynamicColor(light: Color(hex: 0xDB2777), dark: Color(hex: 0xDB2777))
    let domainFeedingBreastBothTint: DynamicColor = DynamicColor(light: Color(hex: 0xFCE7F3), dark: Color(hex: 0xDB2777, opacity: 0.22))
    let domainFeedingSolidsSolid: DynamicColor = DynamicColor(light: Color(hex: 0xA16207), dark: Color(hex: 0xF59E0B))
    let domainFeedingSolidsTint: DynamicColor = DynamicColor(light: Color(hex: 0xFEF3C7), dark: Color(hex: 0xA16207, opacity: 0.22))
    let domainDiaperPeeSolid: DynamicColor = DynamicColor(light: Color(hex: 0x22D3EE), dark: Color(hex: 0x22D3EE))
    let domainDiaperPeeTint: DynamicColor = DynamicColor(light: Color(hex: 0xEFF6FF), dark: Color(hex: 0x22D3EE, opacity: 0.22))
    let domainDiaperPoopSolid: DynamicColor = DynamicColor(light: Color(hex: 0xEAB308), dark: Color(hex: 0xEAB308))
    let domainDiaperPoopTint: DynamicColor = DynamicColor(light: Color(hex: 0xFFF7ED), dark: Color(hex: 0xEAB308, opacity: 0.22))
    let domainDiaperBothSolid: DynamicColor = DynamicColor(light: Color(hex: 0xFB923C), dark: Color(hex: 0xFB923C))
    let domainDiaperBothTint: DynamicColor = DynamicColor(light: Color(hex: 0xFFEDD5), dark: Color(hex: 0xFB923C, opacity: 0.22))
    let domainStoolYellow: DynamicColor = DynamicColor(light: Color(hex: 0xFCD34D), dark: Color(hex: 0xFCD34D))
    let domainStoolGreen: DynamicColor = DynamicColor(light: Color(hex: 0x4ADE80), dark: Color(hex: 0x4ADE80))
    let domainStoolBrown: DynamicColor = DynamicColor(light: Color(hex: 0xA16207), dark: Color(hex: 0xA16207))
    let domainStoolBlack: DynamicColor = DynamicColor(light: Color(hex: 0x1F2937), dark: Color(hex: 0x9CA3AF))
    let domainStoolRed: DynamicColor = DynamicColor(light: Color(hex: 0xEF4444), dark: Color(hex: 0xEF4444))
    let domainStoolWhite: DynamicColor = DynamicColor(light: Color(hex: 0xF3F4F6), dark: Color(hex: 0xF3F4F6))
    let domainSleepSolid: DynamicColor = DynamicColor(light: Color(hex: 0xC084FC), dark: Color(hex: 0xC084FC))
    let domainSleepTint: DynamicColor = DynamicColor(light: Color(hex: 0xFAF5FF), dark: Color(hex: 0xC084FC, opacity: 0.22))
    let domainPlaySolid: DynamicColor = DynamicColor(light: Color(hex: 0x4ADE80), dark: Color(hex: 0x4ADE80))
    let domainPlayTint: DynamicColor = DynamicColor(light: Color(hex: 0xF0FDF4), dark: Color(hex: 0x4ADE80, opacity: 0.22))
}

extension SemanticColorTokens {
    static let `default` = SemanticColorTokens()
}
