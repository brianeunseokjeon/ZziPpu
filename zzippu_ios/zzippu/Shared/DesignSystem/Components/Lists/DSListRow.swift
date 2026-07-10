// Shared/DesignSystem/Components/Lists/DSListRow.swift
// 리스트 행 컴포넌트. variant: plain / navigable(chevron) / withTrailing.
// 조합형: DSListRow { leading } content: { } trailing: { }

import SwiftUI

// MARK: - Variant

public enum DSListRowVariant {
    case plain
    case navigable    // 우측 chevron
    case withTrailing // 우측 커스텀 슬롯
}

// MARK: - DSListRow

/// 조합형 ListRow. leading/content/trailing 슬롯 모두 ViewBuilder.
public struct DSListRow<Leading: View, Content: View, Trailing: View>: View {
    public let variant:  DSListRowVariant
    let leading:  Leading
    let content:  Content
    let trailing: Trailing

    @Environment(\.theme) private var theme

    public var body: some View {
        HStack(spacing: theme.space.stackGapMd) {
            // Leading slot
            leading

            // Content slot (title + subtitle)
            content
                .frame(maxWidth: .infinity, alignment: .leading)

            // Trailing slot or chevron
            switch variant {
            case .plain:
                EmptyView()
            case .navigable:
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.color.textTertiary.color)
            case .withTrailing:
                trailing
            }
        }
        .padding(.horizontal, theme.space.componentPaddingX)
        .frame(minHeight: 44)
        .background(theme.color.surface.color)
        .contentShape(Rectangle())
    }
}

// MARK: - Convenience initialisers

extension DSListRow where Leading == EmptyView {
    /// 리딩 슬롯 없는 편의 init.
    public init(
        variant: DSListRowVariant = .plain,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.variant  = variant
        self.leading  = EmptyView()
        self.content  = content()
        self.trailing = trailing()
    }
}

extension DSListRow where Leading == EmptyView, Trailing == EmptyView {
    public init(
        variant: DSListRowVariant = .plain,
        @ViewBuilder content: () -> Content
    ) {
        self.variant  = variant
        self.leading  = EmptyView()
        self.content  = content()
        self.trailing = EmptyView()
    }
}

extension DSListRow where Trailing == EmptyView {
    public init(
        variant: DSListRowVariant = .plain,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder content: () -> Content
    ) {
        self.variant  = variant
        self.leading  = leading()
        self.content  = content()
        self.trailing = EmptyView()
    }
}

// Full 3-slot init
extension DSListRow {
    public init(
        variant: DSListRowVariant = .plain,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.variant  = variant
        self.leading  = leading()
        self.content  = content()
        self.trailing = trailing()
    }
}

// MARK: - DSListRowDivider

/// 구분선 토큰(divider).
public struct DSListRowDivider: View {
    @Environment(\.theme) private var theme
    public init() {}
    public var body: some View {
        Rectangle()
            .fill(theme.color.divider.color)
            .frame(height: 1)
            .padding(.leading, theme.space.componentPaddingX)
    }
}

// MARK: - Preview

#Preview("DSListRow") {
    VStack(spacing: 0) {
        // plain
        DSListRow(variant: .plain) {
            VStack(alignment: .leading, spacing: 2) {
                Text("수유 기록").font(Theme.zzippu.typography.bodyStrong)
                Text("120ml 분유").font(Theme.zzippu.typography.caption)
                    .foregroundStyle(Theme.zzippu.color.textSecondary.color)
            }
        }
        DSListRowDivider()

        // navigable
        DSListRow(variant: .navigable) {
            Image(systemName: "moon.fill")
                .foregroundStyle(Theme.zzippu.color.domainSleepSolid.color)
        } content: {
            Text("수면 기록")
                .font(Theme.zzippu.typography.bodyStrong)
        }
        DSListRowDivider()

        // withTrailing
        DSListRow(variant: .withTrailing) {
            Image(systemName: "drop.fill")
                .foregroundStyle(Theme.zzippu.color.domainFeedingFormulaSolid.color)
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                Text("분유").font(Theme.zzippu.typography.bodyStrong)
                Text("150ml").font(Theme.zzippu.typography.caption)
                    .foregroundStyle(Theme.zzippu.color.textSecondary.color)
            }
        } trailing: {
            Text("오전 9:30")
                .font(Theme.zzippu.typography.caption)
                .foregroundStyle(Theme.zzippu.color.textTertiary.color)
        }
    }
    .environment(\.theme, .zzippu)
}
