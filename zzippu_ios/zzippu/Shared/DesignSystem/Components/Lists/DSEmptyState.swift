// Shared/DesignSystem/Components/Lists/DSEmptyState.swift
// 아이콘 + 메시지 + 옵션 CTA.

import SwiftUI

public struct DSEmptyState: View {
    public let icon:    String  // SF Symbol name or emoji string
    public let message: String
    public var action:  (label: String, loading: Bool, handler: () -> Void)?

    public init(
        icon:    String = "moon.zzz",
        message: String
    ) {
        self.icon    = icon
        self.message = message
        self.action  = nil
    }

    public init(
        icon:          String = "moon.zzz",
        message:       String,
        actionLabel:   String,
        actionLoading: Bool = false,          // 로딩 시 라벨 유지 + 스피너 → 버튼 폭 불변(축소 방지)
        onAction:      @escaping () -> Void
    ) {
        self.icon    = icon
        self.message = message
        self.action  = (label: actionLabel, loading: actionLoading, handler: onAction)
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        VStack(spacing: theme.space.stackGapMd) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(theme.color.textTertiary.color)

            Text(message)
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textTertiary.color)
                .multilineTextAlignment(.center)

            if let action {
                DSButton(action.label, variant: .tertiary, size: .sm,
                         isLoading: action.loading, action: action.handler)
                    .fixedSize()   // 라벨 기준 폭 고정 — 로딩 스피너로 바뀌어도 축소 안 됨
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.component.emptyStatePaddingY)
    }
}

#Preview("DSEmptyState") {
    VStack(spacing: 40) {
        DSEmptyState(message: "이 날의 기록이 없어요")
        DSEmptyState(
            icon: "drop.slash",
            message: "수유 기록이 없어요",
            actionLabel: "첫 기록 남기기",
            onAction: {}
        )
    }
    .padding()
    .environment(\.theme, .zzippu)
}
