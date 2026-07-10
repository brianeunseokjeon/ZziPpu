// Shared/DesignSystem/Components/Lists/DSSectionHeader.swift
// 섹션 구분 헤더. variant: plain / withAction.

import SwiftUI

public struct DSSectionHeader: View {
    public let title:  String
    public var action: (label: String, handler: () -> Void)?

    public init(title: String) {
        self.title  = title
        self.action = nil
    }

    public init(title: String, actionLabel: String, onAction: @escaping () -> Void) {
        self.title  = title
        self.action = (label: actionLabel, handler: onAction)
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        HStack {
            Text(title)
                .font(theme.typography.captionStrong)
                .foregroundStyle(theme.color.textSecondary.color)
                .textCase(nil)

            Spacer()

            if let action {
                Button(action.label, action: action.handler)
                    .font(theme.typography.captionStrong)
            }
        }
        .padding(.vertical, theme.component.sectionHeaderPaddingY)
        .padding(.horizontal, theme.space.screenPaddingX)
    }
}

#Preview("DSSectionHeader") {
    VStack(spacing: 0) {
        DSSectionHeader(title: "오늘 기록")
        DSSectionHeader(title: "최근 기록", actionLabel: "전체 보기", onAction: {})
    }
    .environment(\.theme, .zzippu)
}
