// Shared/DesignSystem/Components/Navigation/DSTabBar.swift
// 커스텀 탭 바. active(primary, stroke 2.5) / inactive(textTertiary).
// itemMinHeight 56. safe-area 하단 패딩.

import SwiftUI

// MARK: - DSTabItem Model

public struct DSTabItem: Identifiable {
    public let id:         Int
    public let systemName: String  // SF Symbol
    public let label:      String

    public init(id: Int, systemName: String, label: String) {
        self.id         = id
        self.systemName = systemName
        self.label      = label
    }
}

// MARK: - DSTabBarItemView

private struct DSTabBarItemView: View {
    let item:      DSTabItem
    let isActive:  Bool
    let onTap:     () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Image(systemName: item.systemName)
                    .font(.system(size: 22, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive
                        ? theme.color.primary.color
                        : theme.color.textSecondary.color
                    )

                Text(item.label)
                    .font(theme.typography.label)
                    .foregroundStyle(isActive
                        ? theme.color.primary.color
                        : theme.color.textSecondary.color
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}

// MARK: - DSTabBar

public struct DSTabBar: View {
    public let items:      [DSTabItem]
    @Binding public var selection: Int

    public init(items: [DSTabItem], selection: Binding<Int>) {
        self.items      = items
        self._selection = selection
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundStyle(theme.color.divider.color)

            HStack(spacing: 0) {
                ForEach(items) { item in
                    DSTabBarItemView(
                        item:     item,
                        isActive: selection == item.id,
                        onTap:    { selection = item.id }
                    )
                }
            }
            .padding(.bottom, safeAreaBottomPadding)
            .background(theme.color.surface.color)
        }
    }

    // Safe area bottom inset
    private var safeAreaBottomPadding: CGFloat {
        // Get from scene window
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

// MARK: - Preview

private struct DSTabBarPreview: View {
    @State private var selection = 0

    let items = [
        DSTabItem(id: 0, systemName: "house.fill",       label: "홈"),
        DSTabItem(id: 1, systemName: "drop.fill",        label: "수유"),
        DSTabItem(id: 2, systemName: "moon.fill",        label: "수면"),
        DSTabItem(id: 3, systemName: "person.crop.circle", label: "아기"),
    ]

    var body: some View {
        VStack {
            Spacer()
            DSTabBar(items: items, selection: $selection)
        }
        .environment(\.theme, .zzippu)
    }
}

#Preview("DSTabBar") {
    DSTabBarPreview()
}
