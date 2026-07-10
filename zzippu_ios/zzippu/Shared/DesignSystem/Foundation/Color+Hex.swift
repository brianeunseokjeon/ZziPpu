// Shared/DesignSystem/Foundation/Color+Hex.swift
// internal — feature code에서 Color(hex:) 직접 사용 금지.
// 생성된 Tokens 파일 내부에서만 사용됩니다.

import SwiftUI

extension Color {
    /// Creates a Color from a hex integer (e.g. 0x60A5FA).
    /// Alpha is always 1.0; use opacity: for transparency.
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xff) / 255.0
        let g = Double((hex >> 8)  & 0xff) / 255.0
        let b = Double((hex)       & 0xff) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
