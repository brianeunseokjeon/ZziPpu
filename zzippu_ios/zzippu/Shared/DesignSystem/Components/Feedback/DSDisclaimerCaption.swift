// Shared/DesignSystem/Components/Feedback/DSDisclaimerCaption.swift
// 면책 문구 캡션 — info 톤, 작은 텍스트. 분석 카드 하단 고정용.
// info 아이콘 + secondary 텍스트. theme 토큰만 사용(raw 금지).

import SwiftUI

public struct DSDisclaimerCaption: View {
    public let text: String
    public var showIcon: Bool

    /// 표준 면책 문구.
    public static let standard =
        "참고용이며 의학적 진단이 아니에요. 개인차는 정상이며, 이상이 있으면 소아과 상담을 권장드려요."

    public init(_ text: String = DSDisclaimerCaption.standard, showIcon: Bool = true) {
        self.text = text
        self.showIcon = showIcon
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        HStack(alignment: .top, spacing: theme.space.xs) {
            if showIcon {
                Image(systemName: "info.circle")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.statusInfoSolid.color)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textTertiary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("DSDisclaimerCaption — Light") {
    VStack(alignment: .leading, spacing: 12) {
        DSDisclaimerCaption()
        DSDisclaimerCaption("참고용이며 진단이 아니에요 · 출처 AAP·WHO", showIcon: true)
        DSDisclaimerCaption("아이콘 없음 버전", showIcon: false)
    }
    .padding()
    .environment(\.theme, .zzippu)
}

#Preview("DSDisclaimerCaption — Dark") {
    VStack(alignment: .leading, spacing: 12) {
        DSDisclaimerCaption()
        DSDisclaimerCaption("참고용이며 진단이 아니에요 · 출처 AAP·WHO")
    }
    .padding()
    .background(Color.black)
    .environment(\.theme, .zzippu)
    .preferredColorScheme(.dark)
}
