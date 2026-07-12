// Shared/DesignSystem/Components/Buttons/DSButton.swift
// DSButton 래퍼 View + DSButtonStyle (ButtonStyle).
// loading 상태는 래퍼 View 에서 처리 (ButtonStyle.makeBody configuration.label 교체 제한 우회).

import SwiftUI

// MARK: - Variant / Size

extension DSButtonStyle {
    /// 버튼 변형. Open-Closed: 새 케이스 추가 or 별도 ButtonStyle 신규 — 기존 사용처 무영향.
    public enum Variant {
        case primary
        case secondary
        case tertiary   // outline
        case destructive
    }

    /// 버튼 크기. 높이 토큰: sm=36, md=44, lg=56.
    public enum Size {
        case sm, md, lg

        var height: CGFloat {
            switch self {
            case .sm: return 36
            case .md: return 44
            case .lg: return 56
            }
        }

        // 웹정합: 웹 button md=text-base(16), lg=text-lg(18), sm=text-sm(14).
        var font: Font {
            switch self {
            case .sm: return Theme.zzippu.typography.body        // 14
            case .md: return Theme.zzippu.typography.headline    // 16
            case .lg: return Theme.zzippu.typography.title       // 18
            }
        }

        var paddingX: CGFloat {
            switch self {
            case .sm: return 12
            case .md: return 20
            case .lg: return 24
            }
        }
    }
}

// MARK: - DSButtonStyle

public struct DSButtonStyle: ButtonStyle {
    public let variant: Variant
    public let size:    Size

    @Environment(\.theme)     private var theme
    @Environment(\.isEnabled) private var isEnabled

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        // 웹정합: 웹 버튼은 lg도 rounded-xl(12). 전 사이즈 control(12) 라운드로 통일.
        let radius = theme.component.button.radius

        configuration.label
            .font(size.font)
            .fontWeight(size == .sm ? .medium : .semibold)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .foregroundStyle(fgColor(pressed: pressed))
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(bgColor(pressed: pressed))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(borderColor(pressed: pressed), lineWidth: variant == .tertiary ? 1.5 : 0)
                    )
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: pressed)
    }

    // MARK: Colors

    // 비활성: opacity 곱셈 폐기 → 중립 회색 배경/전경 토큰(WCAG 저대비 신호).
    private func bgColor(pressed: Bool) -> Color {
        guard isEnabled else {
            switch variant {
            case .tertiary: return .clear
            default:        return theme.color.primaryDisabledBg.color
            }
        }
        switch variant {
        case .primary:
            // R7(웹정합): 주요 CTA(md/lg)는 웹 bg-blue-500(#3B82F6=statusInfoSolid).
            // sm 인라인 버튼만 웹 button default(bg-blue-400=primary) 유지.
            let base = size == .sm ? theme.color.primary.color : theme.color.statusInfoSolid.color
            return pressed ? theme.color.primaryPressed.color : base
        case .secondary:
            // 프레스 시 살짝 진하게(borderStrong) — 눌림 피드백.
            return pressed ? theme.color.borderStrong.color : theme.color.surfaceSunken.color
        case .tertiary:
            // 프레스 시 옅은 primaryTint 채움.
            return pressed ? theme.color.primaryTint.color : .clear
        case .destructive:
            return pressed ? theme.color.statusDangerFg.color : theme.color.statusDangerSolid.color
        }
    }

    private func fgColor(pressed: Bool) -> Color {
        guard isEnabled else { return theme.color.onPrimaryDisabled.color }
        switch variant {
        case .primary, .destructive:
            return theme.color.onPrimary.color
        case .secondary, .tertiary:
            return pressed
                ? theme.color.primary.color
                : theme.color.textPrimary.color
        }
    }

    private func borderColor(pressed: Bool) -> Color {
        guard variant == .tertiary else { return .clear }
        guard isEnabled else { return theme.color.border.color }
        return pressed ? theme.color.primary.color : theme.color.borderStrong.color
    }
}

// MARK: - DSButtonStyle convenience extension

extension ButtonStyle where Self == DSButtonStyle {
    /// Convenience: `.buttonStyle(.ds(.primary))`
    public static func ds(
        _ variant: DSButtonStyle.Variant,
        size: DSButtonStyle.Size = .md
    ) -> DSButtonStyle {
        DSButtonStyle(variant: variant, size: size)
    }
}

// MARK: - DSButton (loading wrapper)

/// DSButton — 래퍼 View. loading 상태일 때 라벨 자리에 ProgressView 표시.
/// 레이아웃 점프 방지를 위해 동일한 높이/너비를 유지.
public struct DSButton: View {
    public let title: String
    public var variant: DSButtonStyle.Variant
    public var size:    DSButtonStyle.Size
    public var isLoading: Bool
    public let action: () -> Void

    public init(
        _ title: String,
        variant: DSButtonStyle.Variant = .primary,
        size: DSButtonStyle.Size = .md,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title     = title
        self.variant   = variant
        self.size      = size
        self.isLoading = isLoading
        self.action    = action
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        Button(action: isLoading ? {} : action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(variant == .primary || variant == .destructive
                              ? theme.color.onPrimary.color
                              : theme.color.primary.color)
                }
            }
        }
        .buttonStyle(.ds(variant, size: size))
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview("DSButton") {
    ScrollView {
        VStack(spacing: 16) {
            Group {
                DSButton("Primary Button", action: {})
                DSButton("Secondary Button", variant: .secondary, action: {})
                DSButton("Tertiary Button", variant: .tertiary, action: {})
                DSButton("Destructive", variant: .destructive, action: {})
                DSButton("Loading...", isLoading: true, action: {})
                DSButton("Disabled", action: {}).disabled(true)
                DSButton("Small", variant: .primary, size: .sm, action: {})
                DSButton("Large Primary", variant: .primary, size: .lg, action: {})
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
    }
    .environment(\.theme, .zzippu)
}
