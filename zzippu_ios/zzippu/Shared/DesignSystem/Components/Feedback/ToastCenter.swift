// Shared/DesignSystem/Components/Feedback/ToastCenter.swift
// 전역 ToastCenter (@Observable, 단일+교체 정책) + ToastHost 루트 오버레이.
// 정책: 단일 토스트, 새 토스트 발행 시 현재 토스트 교체 (최신 우선).
// variant: success / error / info
// 자동소멸: motion.toastAutoDismissMs (3500ms). 탭 시 즉시 닫힘.
// 진입: slideUp(fast). reduceMotion 시 페이드.

import SwiftUI

// MARK: - ToastVariant

public enum ToastVariant {
    case success
    case error
    case info
}

// MARK: - ToastItem

public struct ToastItem: Equatable, Identifiable {
    public let id:      UUID
    public let message: String
    public let variant: ToastVariant

    public init(message: String, variant: ToastVariant = .info) {
        self.id      = UUID()
        self.message = message
        self.variant = variant
    }

    public static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ToastCenter

/// 앱 루트에서 `@State private var toastCenter = ToastCenter()` 로 보유하고
/// `.environment(toastCenter)` 로 트리 전체에 주입.
@Observable
public final class ToastCenter {
    public private(set) var current: ToastItem?
    private var dismissTask: Task<Void, Never>?

    public init() {}

    /// 새 토스트 발행. 기존 토스트는 즉시 교체.
    public func show(_ item: ToastItem, autoDismissAfter seconds: Double = 3.5) {
        dismissTask?.cancel()
        current = item
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    /// 즉시 닫기.
    public func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        current = nil
    }
}

// MARK: - ToastBubble

private struct ToastBubble: View {
    let item:    ToastItem
    let onDismiss: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: theme.space.stackGapMd) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(fgColor)

            Text(item.message)
                .font(theme.typography.captionStrong)
                .foregroundStyle(fgColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(fgColor.opacity(0.7))
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)
        }
        .padding(.horizontal, theme.space.componentPaddingX)
        .padding(.vertical, theme.space.componentPaddingY)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                .fill(bgColor)
                .shadow(
                    color: theme.shadow.md.color,
                    radius: theme.shadow.md.radius,
                    x: theme.shadow.md.x,
                    y: theme.shadow.md.y
                )
        )
        .padding(.horizontal, theme.space.screenPaddingX)
        .onTapGesture { onDismiss() }
        // Animation
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : (reduceMotion ? 0 : 24))
        .onAppear {
            withAnimation(reduceMotion
                ? .easeIn(duration: theme.motion.fast)
                : .easeOut(duration: theme.motion.fast)
            ) {
                isVisible = true
            }
        }
    }

    // MARK: Helpers

    private var fgColor: Color {
        switch item.variant {
        case .success: return theme.color.statusSuccessFg.color
        case .error:   return theme.color.statusDangerFg.color
        case .info:    return theme.color.textPrimary.color
        }
    }

    private var bgColor: Color {
        switch item.variant {
        case .success: return theme.color.statusSuccessBg.color
        case .error:   return theme.color.statusDangerBg.color
        case .info:    return theme.color.surfaceElevated.color
        }
    }

    private var iconName: String {
        switch item.variant {
        case .success: return "checkmark.circle.fill"
        case .error:   return "exclamationmark.circle.fill"
        case .info:    return "info.circle.fill"
        }
    }
}

// MARK: - ToastHost

/// 앱 루트에 `.overlay(alignment: .bottom) { ToastHost() }` 로 배치.
/// 또는 `ZStack` 최상단에 위치.
public struct ToastHost: View {
    @Environment(ToastCenter.self) private var center
    @Environment(\.theme)          private var theme

    public init() {}

    public var body: some View {
        Group {
            if let item = center.current {
                ToastBubble(item: item, onDismiss: { center.dismiss() })
                    .id(item.id)              // id 변경 시 뷰 교체 → 재애니메이션
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: theme.motion.fast), value: center.current)
        .padding(.bottom, theme.space.md)
    }
}

// MARK: - Preview

private struct ToastPreview: View {
    @State private var center = ToastCenter()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 12) {
                Button("Success 토스트") {
                    center.show(.init(message: "저장 완료!", variant: .success))
                }
                Button("Error 토스트") {
                    center.show(.init(message: "저장에 실패했어요.", variant: .error))
                }
                Button("Info 토스트") {
                    center.show(.init(message: "오늘 기록이 7개예요.", variant: .info))
                }
            }
            .padding()
            .buttonStyle(.ds(.secondary))

            ToastHost()
        }
        .environment(center)
        .environment(\.theme, .zzippu)
    }
}

#Preview("ToastCenter") {
    ToastPreview()
}
