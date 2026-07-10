// Shared/DesignSystem/Components/Lists/TimelineRow.swift
// TimelineItemRow — DayTimeline 한 행.
// TimelineGroupView  — 동일 1분 그룹의 행 묶음 + 하이라이트 variant.
// 1분 단위 그룹핑은 피처 로직 몫(컴포넌트는 표현만).

import SwiftUI

// MARK: - TimelineRowVariant

public enum TimelineRowVariant {
    case normal
    case highlighted  // 최신 그룹: highlightBg + 좌측 highlightBar
}

// MARK: - TimelineItemRow

/// DayTimeline 단일 행.
/// `[mono 시각]  ●  [라벨]  [편집 아이콘버튼]`
/// `dotColor`: theme.color.solid(for: kind).color 로 해석된 Color를 주입한다.
public struct TimelineItemRow: View {
    public let time:      String   // e.g. "09:30"
    public let label:     String
    public let dotColor:  Color    // domain.*.solid.color 주입
    public var onEdit:    (() -> Void)?

    public init(
        time:     String,
        label:    String,
        dotColor: Color,
        onEdit:   (() -> Void)? = nil
    ) {
        self.time     = time
        self.label    = label
        self.dotColor = dotColor
        self.onEdit   = onEdit
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        HStack(spacing: theme.space.stackGapSm) {
            // Mono time
            Text(time)
                .font(theme.typography.mono)
                .foregroundStyle(theme.color.textSecondary.color)
                .frame(width: 48, alignment: .trailing)

            // Dot (10pt — 왜소한 점 → 또렷한 색 마커)
            Circle()
                .fill(dotColor)
                .frame(width: theme.component.timelineDotSize, height: theme.component.timelineDotSize)

            // Label
            Text(label)
                .font(theme.typography.body)
                .foregroundStyle(theme.color.textPrimary.color)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Edit button
            if let onEdit {
                DSIconButton(systemName: "pencil", action: onEdit)
            }
        }
        // 좌우 패딩은 섹션(screenPaddingX)이 담당 — 이중 패딩(32pt) 제거.
        .frame(minHeight: 44)
    }
}

// MARK: - TimelineGroupView

/// 동일 1분 그룹 묶음. variant에 따라 배경 + 좌측 바 강조.
public struct TimelineGroupView<Rows: View>: View {
    public let variant: TimelineRowVariant
    let rows: Rows

    public init(
        variant: TimelineRowVariant = .normal,
        @ViewBuilder rows: () -> Rows
    ) {
        self.variant = variant
        self.rows    = rows()
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        ZStack(alignment: .leading) {
            // Highlight background
            if variant == .highlighted {
                theme.color.primaryTint.color
                    .cornerRadius(theme.radius.control)
            }

            // Highlight left bar
            if variant == .highlighted {
                Rectangle()
                    .fill(theme.color.primary.color)
                    .frame(width: 3)
                    .cornerRadius(2)
                    .padding(.vertical, 4)
            }

            VStack(spacing: 0) {
                rows
            }
            .padding(.leading, variant == .highlighted ? 3 : 0)
        }
    }
}

// MARK: - Preview

private struct TimelineRowPreview: View {
    var body: some View {
        let theme = Theme.zzippu
        VStack(spacing: 0) {
            TimelineGroupView(variant: .highlighted) {
                TimelineItemRow(
                    time:     "09:30",
                    label:    "분유 120ml",
                    dotColor: theme.color.domainFeedingFormulaSolid.color,
                    onEdit:   {}
                )
                TimelineItemRow(
                    time:     "09:31",
                    label:    "왼쪽 모유 10분",
                    dotColor: theme.color.domainFeedingBreastLeftSolid.color,
                    onEdit:   {}
                )
            }
            DSListRowDivider()
            TimelineGroupView(variant: .normal) {
                TimelineItemRow(
                    time:     "08:00",
                    label:    "수면 시작",
                    dotColor: theme.color.domainSleepSolid.color,
                    onEdit:   {}
                )
            }
        }
        .padding()
        .environment(\.theme, .zzippu)
    }
}

#Preview("TimelineRow") {
    TimelineRowPreview()
}
