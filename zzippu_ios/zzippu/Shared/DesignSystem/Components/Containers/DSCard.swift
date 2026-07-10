// Shared/DesignSystem/Components/Containers/DSCard.swift
// CardContainer + .dsCard() ViewModifier.

import SwiftUI

// MARK: - DSCard Style

public enum DSCardStyle {
    case plain       // 테두리 + shadow-sm
    case sunken      // surfaceSunken 배경, 그림자 없음
    case interactive // 탭 시 press 피드백
}

// MARK: - DSCard ViewModifier

public struct DSCardModifier: ViewModifier {
    public let style: DSCardStyle

    @Environment(\.theme) private var theme
    @State private var isPressed = false

    public func body(content: Content) -> some View {
        content
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.component.card.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.component.card.radius, style: .continuous)
                    .stroke(theme.color.border.color, lineWidth: style == .plain ? 1 : 0)
            )
            .dsShadow(style == .sunken ? PrimitiveShadow.shadowNone : theme.component.card.shadow)
            .scaleEffect(style == .interactive && isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .gesture(style == .interactive
                ? DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded   { _ in isPressed = false }
                : nil)
    }

    private var bgColor: Color {
        switch style {
        case .plain, .interactive:
            return theme.color.surface.color
        case .sunken:
            return theme.color.surfaceSunken.color
        }
    }
}

extension View {
    public func dsCard(style: DSCardStyle = .plain) -> some View {
        modifier(DSCardModifier(style: style))
    }
}

// MARK: - CardContainer

/// 조합형 카드 컨테이너 (slot: header/content).
public struct CardContainer<Content: View>: View {
    public let style:    DSCardStyle
    public let content: Content

    public init(
        style: DSCardStyle = .plain,
        @ViewBuilder content: () -> Content
    ) {
        self.style   = style
        self.content = content()
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        content
            .padding(theme.component.card.padding)
            .dsCard(style: style)
    }
}

// MARK: - Preview

#Preview("DSCard") {
    ScrollView {
        VStack(spacing: 16) {
            CardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plain Card").font(.headline)
                    Text("카드 기본 스타일 — 테두리 + shadow-sm").font(.caption)
                }
            }

            CardContainer(style: .sunken) {
                Text("Sunken Card — 함몰 배경, 그림자 없음")
                    .font(.caption)
            }

            CardContainer(style: .interactive) {
                Text("Interactive Card — 탭 피드백")
                    .font(.caption)
            }
        }
        .padding(16)
    }
    .environment(\.theme, .zzippu)
}
