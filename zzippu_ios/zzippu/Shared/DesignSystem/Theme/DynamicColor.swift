// Shared/DesignSystem/Theme/DynamicColor.swift
// Light/dark 색 쌍을 담고 시스템 colorScheme 에 따라 자동 해석.

import SwiftUI

/// 라이트/다크 두 색을 갖는 래퍼.
/// `Color(uiColor:)` 기반으로 시스템 다크모드를 자동 반영한다.
/// Feature 코드는 이 타입을 `Color`처럼 `.foregroundStyle`, `.background` 등에 직접 사용한다.
struct DynamicColor {
    let light: Color
    let dark: Color

    init(light: Color, dark: Color) {
        self.light = light
        self.dark  = dark
    }

    /// 현재 `UITraitCollection` (시스템 컬러스킴)에 맞는 `Color` 반환.
    /// SwiftUI 환경에서 자동 업데이트.
    var color: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - View modifiers

extension View {
    func foregroundStyle(_ dc: DynamicColor) -> some View {
        foregroundStyle(dc.color)
    }

    func background(_ dc: DynamicColor) -> some View {
        background(dc.color)
    }
}

// MARK: - ShapeStyle conformance helper (used in .tint, .fill, etc.)

extension DynamicColor {
    /// 명시적으로 Color 로 변환이 필요할 때 사용.
    /// 일반적으로 `.color` 프로퍼티를 쓴다.
    func asColor() -> Color { color }
}
