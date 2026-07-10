// Shared/DesignSystem/Theme/EnvironmentTheme.swift
// @Environment(\.theme) 키 정의.

import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .zzippu
}

extension EnvironmentValues {
    /// 앱 루트에서 `.environment(\.theme, .zzippu)` 으로 주입.
    /// 서버주도 리브랜딩 시 Theme(from: serverPayload) 를 넣어 교체.
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
