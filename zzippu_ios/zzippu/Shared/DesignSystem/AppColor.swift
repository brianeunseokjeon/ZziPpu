// Shared/DesignSystem/AppColor.swift
// ⚠️ DEPRECATED — 신 Theme.color.* 으로 이전 진행 중.
// 기존 화면 컴파일 유지를 위해 Theme.zzippu 토큰을 가리키는 별칭으로 유지.
// 새 코드에서는 @Environment(\.theme) 을 사용하세요.

import SwiftUI

enum AppColor {
    // MARK: Surface / Background
    @available(*, deprecated, message: "Use theme.color.background.color")
    static let background: Color = Theme.zzippu.color.background.color

    @available(*, deprecated, message: "Use theme.color.surface.color")
    static let surface: Color = Theme.zzippu.color.surface.color

    // MARK: Text
    @available(*, deprecated, message: "Use theme.color.textPrimary.color")
    static let textPrimary: Color = Theme.zzippu.color.textPrimary.color

    @available(*, deprecated, message: "Use theme.color.textSecondary.color")
    static let textSecondary: Color = Theme.zzippu.color.textSecondary.color

    // MARK: Primary
    @available(*, deprecated, message: "Use theme.color.primary.color")
    static let primary: Color = Theme.zzippu.color.primary.color

    // MARK: Domain — Feeding (기존 화면 호환용)
    @available(*, deprecated, message: "Use theme.color.domainFeedingFormulaSolid.color")
    static let formula: Color = Theme.zzippu.color.domainFeedingFormulaSolid.color

    @available(*, deprecated, message: "Use theme.color.domainFeedingBreastLeftSolid.color")
    static let breastLeft: Color = Theme.zzippu.color.domainFeedingBreastLeftSolid.color

    @available(*, deprecated, message: "Use theme.color.domainFeedingBreastRightSolid.color")
    static let breastRight: Color = Theme.zzippu.color.domainFeedingBreastRightSolid.color

    @available(*, deprecated, message: "Use theme.color.domainFeedingBreastBothSolid.color")
    static let breastBoth: Color = Theme.zzippu.color.domainFeedingBreastBothSolid.color
}
