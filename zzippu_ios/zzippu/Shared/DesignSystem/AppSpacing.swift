// Shared/DesignSystem/AppSpacing.swift
// ⚠️ DEPRECATED — 신 Theme.space.* 으로 이전 진행 중.
// 기존 화면 컴파일 유지를 위해 Theme.zzippu 토큰을 가리키는 별칭으로 유지.
// 새 코드에서는 @Environment(\.theme) 을 사용하세요.

import Foundation

enum AppSpacing {
    @available(*, deprecated, message: "Use theme.space.xs")
    static let xs:  CGFloat = Theme.zzippu.space.xs

    @available(*, deprecated, message: "Use theme.space.sm")
    static let sm:  CGFloat = Theme.zzippu.space.sm

    @available(*, deprecated, message: "Use theme.space.md")
    static let md:  CGFloat = Theme.zzippu.space.md

    @available(*, deprecated, message: "Use theme.space.lg")
    static let lg:  CGFloat = Theme.zzippu.space.lg

    @available(*, deprecated, message: "Use theme.space.xl")
    static let xl:  CGFloat = Theme.zzippu.space.xl

    @available(*, deprecated, message: "Use theme.space.xxl (= 48)")
    static let xxl: CGFloat = 48
}
