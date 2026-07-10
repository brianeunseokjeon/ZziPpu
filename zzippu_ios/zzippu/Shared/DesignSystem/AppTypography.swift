// Shared/DesignSystem/AppTypography.swift
// ⚠️ DEPRECATED — 신 Theme.typography.* 으로 이전 진행 중.
// 기존 화면 컴파일 유지를 위해 Theme.zzippu 토큰을 가리키는 별칭으로 유지.
// 새 코드에서는 @Environment(\.theme) 을 사용하세요.

import SwiftUI

enum AppTypography {
    @available(*, deprecated, message: "Use theme.typography.display")
    static let largeTitle:   Font = Theme.zzippu.typography.display

    @available(*, deprecated, message: "Use theme.typography.title")
    static let title1:       Font = Theme.zzippu.typography.title

    @available(*, deprecated, message: "Use theme.typography.headline")
    static let title2:       Font = Theme.zzippu.typography.headline

    @available(*, deprecated, message: "Use theme.typography.title")
    static let title3:       Font = Theme.zzippu.typography.title

    @available(*, deprecated, message: "Use theme.typography.headline")
    static let headline:     Font = Theme.zzippu.typography.headline

    @available(*, deprecated, message: "Use theme.typography.callout")
    static let subheadline:  Font = Theme.zzippu.typography.callout

    @available(*, deprecated, message: "Use theme.typography.body")
    static let body:         Font = Theme.zzippu.typography.body

    @available(*, deprecated, message: "Use theme.typography.callout")
    static let callout:      Font = Theme.zzippu.typography.callout

    @available(*, deprecated, message: "Use theme.typography.caption")
    static let caption:      Font = Theme.zzippu.typography.caption

    @available(*, deprecated, message: "Use theme.typography.label")
    static let caption2:     Font = Theme.zzippu.typography.label
}
