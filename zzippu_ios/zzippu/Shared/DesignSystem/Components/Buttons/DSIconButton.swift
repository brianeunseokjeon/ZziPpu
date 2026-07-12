// Shared/DesignSystem/Components/Buttons/DSIconButton.swift
// 아이콘 전용 버튼. 44pt 터치타깃 강제.

import SwiftUI

public enum DSIconButtonVariant {
    case plain   // 투명 배경
    case tinted  // primaryTint 배경
}

public enum DSIconButtonTint {
    case secondary  // 기본 — textSecondary
    case tertiary   // 연한 회색(gray-300 급) — 타임라인 편집 연필 등 비강조 아이콘
}

public struct DSIconButton: View {
    public let systemName: String
    public var variant: DSIconButtonVariant
    public var iconSize: CGFloat
    public var tint: DSIconButtonTint
    public let action: () -> Void

    public init(
        systemName: String,
        variant: DSIconButtonVariant = .plain,
        iconSize: CGFloat = 20,
        tint: DSIconButtonTint = .secondary,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.variant    = variant
        self.iconSize   = iconSize
        self.tint       = tint
        self.action     = action
    }

    @Environment(\.theme) private var theme

    private var fg: Color {
        switch tint {
        case .secondary: return theme.color.textSecondary.color
        case .tertiary:  return theme.color.textTertiary.color
        }
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(fg)
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
