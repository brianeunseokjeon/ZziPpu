// Shared/DesignSystem/Components/Buttons/DSIconButton.swift
// 아이콘 전용 버튼. 44pt 터치타깃 강제.

import SwiftUI

public enum DSIconButtonVariant {
    case plain   // 투명 배경
    case tinted  // primaryTint 배경
}

public struct DSIconButton: View {
    public let systemName: String
    public var variant: DSIconButtonVariant
    public let action: () -> Void

    public init(
        systemName: String,
        variant: DSIconButtonVariant = .plain,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.variant    = variant
        self.action     = action
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(theme.color.textSecondary.color)
                .frame(width: theme.component.iconButtonSize,
                       height: theme.component.iconButtonSize)
                .background(
                    Circle()
                        .fill(variant == .tinted
                              ? theme.color.primaryTint.color
                              : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview("DSIconButton") {
    HStack(spacing: 16) {
        DSIconButton(systemName: "pencil", action: {})
        DSIconButton(systemName: "trash", variant: .tinted, action: {})
        DSIconButton(systemName: "xmark", action: {})
    }
    .padding()
    .environment(\.theme, .zzippu)
}
