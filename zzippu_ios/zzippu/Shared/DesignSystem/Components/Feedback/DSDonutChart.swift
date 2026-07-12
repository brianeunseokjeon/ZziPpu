// Shared/DesignSystem/Components/Feedback/DSDonutChart.swift
// 비중(구성비) 도넛 차트 — Swift Charts SectorMark(iOS17+).
// Domain 비의존: 값·색·라벨만 주입. theme 토큰만 사용(raw 색 금지 — 색은 호출자가 토큰 Color로 주입).
// 카드 미니(sm, 라벨 숨김) + 상세(lg, 범례) 재사용.

import SwiftUI
import Charts

// MARK: - DSDonutSegment

/// 도넛 한 세그먼트. value=비중 원값(합산은 컴포넌트가), color=theme 토큰 Color, label=범례 텍스트.
public struct DSDonutSegment: Identifiable, Equatable {
    public let id: String
    public let value: Double
    public let color: Color
    public let label: String

    public init(id: String = UUID().uuidString, value: Double, color: Color, label: String) {
        self.id = id
        self.value = value
        self.color = color
        self.label = label
    }
}

// MARK: - DSDonutChart

public struct DSDonutChart: View {

    public enum Size {
        case sm   // 카드 미니 — 라벨 숨김
        case lg   // 상세 — 범례 표기

        var diameter: CGFloat { self == .sm ? 72 : 140 }
        var innerRatio: CGFloat { 0.62 }
        var centerFont: Font { self == .sm ? .system(size: 15, weight: .bold, design: .rounded)
                                            : .system(size: 22, weight: .bold, design: .rounded) }
        var centerCaptionFont: Font { .system(size: 10, weight: .medium) }
    }

    public let segments: [DSDonutSegment]
    public let centerText: String?
    public let centerCaption: String?
    public let size: Size
    public let showLegend: Bool

    public init(
        segments: [DSDonutSegment],
        centerText: String? = nil,
        centerCaption: String? = nil,
        size: Size = .sm,
        showLegend: Bool = false
    ) {
        self.segments = segments
        self.centerText = centerText
        self.centerCaption = centerCaption
        self.size = size
        self.showLegend = showLegend
    }

    @Environment(\.theme) private var theme

    private var total: Double { segments.reduce(0) { $0 + $1.value } }
    private var hasData: Bool { total > 0 && !segments.isEmpty }

    public var body: some View {
        HStack(spacing: 12) {
            donut
            if showLegend && hasData {
                legend
            }
        }
    }

    @ViewBuilder
    private var donut: some View {
        ZStack {
            if hasData {
                Chart(segments) { seg in
                    SectorMark(
                        angle: .value("비중", seg.value),
                        innerRadius: .ratio(size.innerRatio),
                        angularInset: 1.2
                    )
                    .foregroundStyle(seg.color)
                    .cornerRadius(2)
                }
                .chartLegend(.hidden)
            } else {
                // 데이터 없음 — 완곡한 빈 링
                Circle()
                    .stroke(theme.color.surfaceSunken.color,
                            style: StrokeStyle(lineWidth: size.diameter * (1 - size.innerRatio) / 2))
                    .padding(size.diameter * (1 - size.innerRatio) / 4)
            }

            centerLabel
        }
        .frame(width: size.diameter, height: size.diameter)
    }

    @ViewBuilder
    private var centerLabel: some View {
        VStack(spacing: 1) {
            if hasData, let centerText {
                Text(centerText)
                    .font(size.centerFont)
                    .foregroundStyle(theme.color.textPrimary.color)
                    .dsDynamicTypeCap()
            } else if !hasData {
                Text("—")
                    .font(size.centerFont)
                    .foregroundStyle(theme.color.textTertiary.color)
            }
            if let centerCaption, hasData {
                Text(centerCaption)
                    .font(size.centerCaptionFont)
                    .foregroundStyle(theme.color.textTertiary.color)
            }
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(segments) { seg in
                HStack(spacing: 6) {
                    Circle()
                        .fill(seg.color)
                        .frame(width: 8, height: 8)
                    Text(seg.label)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textSecondary.color)
                    Spacer(minLength: 0)
                    Text(percentText(seg.value))
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textPrimary.color)
                }
            }
        }
    }

    private func percentText(_ value: Double) -> String {
        guard total > 0 else { return "0%" }
        return "\(Int((value / total * 100).rounded()))%"
    }
}

// MARK: - Preview

private struct DSDonutChartPreview: View {
    @Environment(\.theme) private var theme
    var body: some View {
        VStack(spacing: 28) {
            DSDonutChart(
                segments: [
                    DSDonutSegment(value: 420, color: theme.color.domainFeedingFormulaSolid.color, label: "분유"),
                    DSDonutSegment(value: 260, color: theme.color.domainFeedingBreastBothSolid.color, label: "모유")
                ],
                centerText: "680",
                centerCaption: "ml",
                size: .sm
            )

            DSDonutChart(
                segments: [
                    DSDonutSegment(value: 5, color: theme.color.domainDiaperPeeSolid.color, label: "소변"),
                    DSDonutSegment(value: 3, color: theme.color.domainDiaperPoopSolid.color, label: "대변")
                ],
                centerText: "8",
                centerCaption: "회",
                size: .lg,
                showLegend: true
            )

            // 데이터 없음
            DSDonutChart(segments: [], centerText: nil, size: .sm)
        }
        .padding()
    }
}

#Preview("DSDonutChart — light") {
    DSDonutChartPreview()
        .environment(\.theme, .zzippu)
}

#Preview("DSDonutChart — dark") {
    DSDonutChartPreview()
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
