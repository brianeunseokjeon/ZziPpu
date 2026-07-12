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
    public var variant:   TimelineRowVariant
    public var onEdit:    (() -> Void)?

    public init(
        time:     String,
        label:    String,
        dotColor: Color,
        variant:  TimelineRowVariant = .normal,
        onEdit:   (() -> Void)? = nil
    ) {
        self.time     = time
        self.label    = label
        self.dotColor = dotColor
        self.variant  = variant
        self.onEdit   = onEdit
    }

    @Environment(\.theme) private var theme

    private var isNewest: Bool { variant == .highlighted }

    public var body: some View {
        // 웹 정합: [시간 w-16] gap-3 [ ●(dot) gap-2 라벨 … 연필 ]
        HStack(spacing: theme.space.stackGapMd) {              // 12 — 웹 gap-3(시간↔내용)
            // Mono time — 웹: mono. 일반=gray-400 normal / 최신=blue-500 bold, "최신" 9pt blue-400.
            VStack(alignment: .leading, spacing: 0) {
                Text(time)
                    .font(theme.typography.mono)
                    .fontWeight(isNewest ? .bold : .regular)  // 일반은 웹처럼 normal(굵기 과함 방지)
                    .foregroundStyle(isNewest ? theme.color.statusInfoSolid.color
                                              : theme.color.textTertiary.color)
                if isNewest {
                    Text("최신")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(theme.color.primary.color)
                }
            }
            .frame(width: 72, alignment: .leading)            // 오전/오후 병기 폭 확보(w-16→72)

            HStack(spacing: theme.space.stackGapSm) {          // 8 — 웹 gap-2(dot↔라벨)
                // Dot — 웹: 최신 w-2(8pt) / 일반 w-1.5(6pt).
                Circle()
                    .fill(dotColor)
                    .frame(width: isNewest ? 8 : 6,
                           height: isNewest ? 8 : 6)

                // Label — 웹: 최신 semibold / 일반 normal.
                Text(label)
                    .font(theme.typography.body)
                    .fontWeight(isNewest ? .semibold : .regular)  // 일반 normal — 웹과 동일 굵기
                    .foregroundStyle(theme.color.textPrimary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 상세로 이동 표시(화살표) — 탭은 아이콘이 아니라 "행 전체"가 처리한다.
                if onEdit != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.color.textTertiary.color)
                        .frame(width: 24, height: 24)   // 시각 정렬용 여백
                }
            }
        }
        // 좌우/상하 패딩은 그룹(TimelineGroupView)이 담당. 행 높이는 웹 min-h-1.8rem(≈29).
        .frame(minHeight: 29)
        // 행 전체를 탭하면 편집 모달 오픈(아이콘만이 아니라 UI 전체).
        .contentShape(Rectangle())
        .onTapGesture { onEdit?() }
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
            // Highlight background — 웹 bg-blue-50/70 (primaryTint=blue-50, 70%). 전폭·모서리 각짐(웹 동일).
            if variant == .highlighted {
                theme.color.primaryTint.color
                    .opacity(0.7)
            }

            // Content — 웹 px-4 py-2.5. 내부 패딩을 그룹이 담당(하이라이트 배경이 콘텐츠를 감싼다).
            VStack(spacing: theme.space.xs) {                 // 4 — 웹 space-y-0.5 근사(묶음 내 행 간격)
                rows
            }
            .padding(.horizontal, theme.space.screenPaddingX) // 16 — 웹 px-4(좌측 바에 글자 밀착 방지)
            .padding(.vertical, theme.space.stackGapSm + 2)   // 10 — 웹 py-2.5(행 간격 확보)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Highlight left bar — 웹 border-l-[3px] blue-400: 맨 왼쪽·전체 높이·직선(라운드 없음).
            if variant == .highlighted {
                Rectangle()
                    .fill(theme.color.primary.color)
                    .frame(width: 3)
            }
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
                    variant:  .highlighted,
                    onEdit:   {}
                )
                TimelineItemRow(
                    time:     "09:31",
                    label:    "왼쪽 모유 10분",
                    dotColor: theme.color.domainFeedingBreastLeftSolid.color,
                    variant:  .highlighted,
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
