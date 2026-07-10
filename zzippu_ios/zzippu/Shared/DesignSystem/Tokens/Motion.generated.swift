// AUTO-GENERATED — 손대지 말 것
// Source: docs/design-system/tokens.json
// Generator: tools/gen-tokens.mjs  (node tools/gen-tokens.mjs)
// ⚠️  이 파일을 직접 수정하면 토큰 재생성 시 덮어씁니다.

import SwiftUI

// MARK: - Motion Tokens

enum DSMotion {
    /// 버튼/토스트 진입 — 200ms
    static let fast: Double = 0.2
    /// 시트 전환 — 300ms
    static let normal: Double = 0.3
    /// 느린 전환 — 500ms
    static let slow: Double = 0.5
    /// 토스트 자동 소멸 — 3500ms
    static let toastAutoDismiss: Double = 3.5
    /// SwiftUI spring: response=0.35, damping=0.85
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.85)
    static let springFast: Animation = .spring(response: 0.21, dampingFraction: 0.85)
}
