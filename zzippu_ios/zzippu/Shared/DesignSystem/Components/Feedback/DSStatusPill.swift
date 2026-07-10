// Shared/DesignSystem/Components/Feedback/DSStatusPill.swift
// 상태 배지. tone은 semantic.color.status.* 에서 색 가져옴.
// 텍스트 병기 필수 — 색만으로 의미 전달 금지.

import SwiftUI

public struct DSStatusPill: View {
    public let tone: StatusTone
    public let text: String

    public init(tone: StatusTone, text: String) {
        self.tone = tone
        self.text = text
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        let colors = theme.color.status(tone: tone)
        Text(text)
            .font(theme.typography.captionStrong)
            .foregroundStyle(colors.fg.color)
            .padding(.horizontal, theme.component.statusPillPaddingX)
            .padding(.vertical, theme.component.statusPillPaddingY)
            .background(colors.bg.color)
            .clipShape(Capsule())
    }
}

#Preview("DSStatusPill") {
    HStack(spacing: 8) {
        DSStatusPill(tone: .success, text: "적정")
        DSStatusPill(tone: .warning, text: "권장보다 적음")
        DSStatusPill(tone: .danger,  text: "초과")
        DSStatusPill(tone: .info,    text: "저장 중")
    }
    .padding()
    .environment(\.theme, .zzippu)
}
