// AUTO-GENERATED — 손대지 말 것
// Source: docs/design-system/tokens.json
// Generator: tools/gen-tokens.mjs  (node tools/gen-tokens.mjs)
// ⚠️  이 파일을 직접 수정하면 토큰 재생성 시 덮어씁니다.

import SwiftUI

// MARK: - Primitive Shadows

struct DSShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum PrimitiveShadow {
    static let shadowNone = DSShadowStyle(color: .clear.opacity(0), radius: 0, x: 0, y: 0)
    static let shadowSm = DSShadowStyle(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    static let shadowMd = DSShadowStyle(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    static let shadowLg = DSShadowStyle(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
    static let shadowXl = DSShadowStyle(color: .black.opacity(0.12), radius: 12.5, x: 0, y: 20)
}
