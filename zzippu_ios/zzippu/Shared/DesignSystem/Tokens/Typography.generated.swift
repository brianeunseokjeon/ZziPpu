// AUTO-GENERATED — 손대지 말 것
// Source: docs/design-system/tokens.json
// Generator: tools/gen-tokens.mjs  (node tools/gen-tokens.mjs)
// ⚠️  이 파일을 직접 수정하면 토큰 재생성 시 덮어씁니다.

import SwiftUI

// MARK: - Semantic Typography
// Dynamic Type 유지: TextStyle 매핑. display/mono는 상한(.xxLarge) 적용.

struct SemanticTypography {
    /// display: textStyle=.largeTitle, weight=.regular, dynamicTypeSize ≤ .xxLarge
    let display: Font = .system(.largeTitle).weight(.regular)

    /// title: textStyle=.title3, weight=.regular
    let title: Font = .system(.title3).weight(.regular)

    /// headline: textStyle=.headline, weight=.regular
    let headline: Font = .system(.headline).weight(.regular)

    /// body: textStyle=.body, weight=.regular
    let body: Font = .system(.body).weight(.regular)

    /// bodyStrong: textStyle=.body, weight=.regular
    let bodyStrong: Font = .system(.body).weight(.regular)

    /// callout: textStyle=.callout, weight=.regular
    let callout: Font = .system(.callout).weight(.regular)

    /// caption: textStyle=.caption, weight=.regular
    let caption: Font = .system(.caption).weight(.regular)

    /// captionStrong: textStyle=.caption, weight=.regular
    let captionStrong: Font = .system(.caption).weight(.regular)

    /// label: textStyle=.caption2, weight=.regular
    let label: Font = .system(.caption2).weight(.regular)

    /// mono: textStyle=.caption2, weight=.regular, dynamicTypeSize ≤ .xxLarge
    let mono: Font = .system(.caption2, design: .monospaced).weight(.regular)

}

extension SemanticTypography {
    static let `default` = SemanticTypography()
}

// MARK: - View modifier for capping Dynamic Type
extension View {
    /// display/mono 스타일에 적용. 접근성 초대형에서 레이아웃 보호.
    @ViewBuilder
    func dsDynamicTypeCap() -> some View {
        if #available(iOS 15.0, *) {
            self.dynamicTypeSize(...DynamicTypeSize.xxLarge)
        } else {
            self
        }
    }
}
