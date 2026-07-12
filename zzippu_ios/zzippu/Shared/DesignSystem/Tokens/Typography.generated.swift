// AUTO-GENERATED — 손대지 말 것
// Source: docs/design-system/tokens.json
// Generator: tools/gen-tokens.mjs  (node tools/gen-tokens.mjs)
// ⚠️  이 파일을 직접 수정하면 토큰 재생성 시 덮어씁니다.

import SwiftUI

// MARK: - Semantic Typography
// 고정 pt 방출(웹 px 1:1 수렴). Dynamic Type은 뷰단 상한만 허용(dsTypeCap / dsDynamicTypeCap).
// pt/weight 값은 전부 tokens.json(primitive.font.scale·semantic.typography)에서 옴.

struct SemanticTypography {
    /// display: 36pt, weight=.bold, design=.rounded, dynamicTypeSize ≤ .xxLarge
    let display: Font = .system(size: 36, weight: .bold, design: .rounded)

    /// title: 18pt, weight=.semibold
    let title: Font = .system(size: 18, weight: .semibold)

    /// headline: 16pt, weight=.semibold
    let headline: Font = .system(size: 16, weight: .semibold)

    /// headlineStrong: 16pt, weight=.bold
    let headlineStrong: Font = .system(size: 16, weight: .bold)

    /// body: 14pt, weight=.medium
    let body: Font = .system(size: 14, weight: .medium)

    /// bodyStrong: 14pt, weight=.semibold
    let bodyStrong: Font = .system(size: 14, weight: .semibold)

    /// callout: 14pt, weight=.medium
    let callout: Font = .system(size: 14, weight: .medium)

    /// caption: 12pt, weight=.regular
    let caption: Font = .system(size: 12, weight: .regular)

    /// captionStrong: 12pt, weight=.semibold
    let captionStrong: Font = .system(size: 12, weight: .semibold)

    /// label: 12pt, weight=.medium, tracking=+0.3
    let label: Font = .system(size: 12, weight: .medium)
    let labelTracking: CGFloat = 0.3

    /// mono: 12pt, weight=.medium, design=.monospaced, dynamicTypeSize ≤ .xxLarge
    let mono: Font = .system(size: 12, weight: .medium, design: .monospaced)

    /// input: 16pt 고정 — iOS 자동줌 방지(callout 14와 분리)
    let input: Font = .system(size: 16, weight: .regular)

}

extension SemanticTypography {
    static let `default` = SemanticTypography()
}

// MARK: - View modifiers for capping Dynamic Type
extension View {
    /// 전역 상한: 고정 pt 위에 접근성만 제한적으로 허용(신생아 아빠 배려 + 웹 레이아웃 유지).
    /// 앱 루트에 1회 적용 권장.
    @ViewBuilder
    func dsTypeCap() -> some View {
        if #available(iOS 15.0, *) {
            self.dynamicTypeSize(...DynamicTypeSize.xLarge)
        } else {
            self
        }
    }

    /// display/mono 등 큰 숫자·모노 스타일 국소 상한. 초대형에서 레이아웃 보호.
    @ViewBuilder
    func dsDynamicTypeCap() -> some View {
        if #available(iOS 15.0, *) {
            self.dynamicTypeSize(...DynamicTypeSize.xxLarge)
        } else {
            self
        }
    }
}
