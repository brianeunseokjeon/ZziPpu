// Feature/Dashboard/MetricDetailView.swift
// 수유/수면/기저귀/놀이 상세 차트 화면 — 기간 토글 + Swift Charts + 인사이트.
// 건강앱 상세 패턴: 큰 차트 + DSChip 세그먼트 + TrendInsightCard.

import SwiftUI
import Charts

// MARK: - TrendInsightCard

struct TrendInsightCard: View {
    let insightText: String
    let tone: StatusTone

    @Environment(\.theme) private var theme

    var body: some View {
        CardContainer(style: .sunken) {
            HStack(spacing: 12) {
                DSStatusPill(tone: tone, text: toneLabel)
                Text(insightText)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.color.textPrimary.color)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }

    private var toneLabel: String {
        switch tone {
        case .success: return "양호"
        case .warning: return "주의"
        case .danger:  return "부족"
        case .info:    return "참고"
        }
    }
}

// MARK: - RangePicker

struct RangePicker: View {
    @Binding var selection: TrendRange

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TrendRange.allCases) { range in
                DSChip(
                    label:      range.rawValue,
                    isSelected: selection == range,
                    variant:    .selectable,
                    onTap:      { selection = range }
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - FeedingDetailView

struct FeedingDetailView: View {

    let dashboardVM: DashboardViewModel
    @State private var range: TrendRange = .week
    @Environment(\.theme) private var theme

    private let trendUseCase = ComputeTrendUseCase()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RangePicker(selection: $range)

                // 큰 차트
                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("수유량 추이 (ml)")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)

                        let points = trendUseCase.feedingTrend(
                            feedings: dashboardVM.sparkFeedings,
                            range: range,
                            anchorDate: dashboardVM.selectedDate
                        )
                        let avg = trendUseCase.average(of: points)

                        Chart {
                            ForEach(points) { point in
                                BarMark(
                                    x: .value("날짜", point.date, unit: .day),
                                    y: .value("ml", point.value)
                                )
                                .foregroundStyle(theme.color.domainFeedingFormulaSolid.color)
                                .cornerRadius(4)
                            }

                            if avg > 0 {
                                RuleMark(y: .value("평균", avg))
                                    .foregroundStyle(theme.color.textTertiary.color)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                                    .annotation(position: .top, alignment: .trailing) {
                                        Text("평균 \(Int(avg))ml")
                                            .font(theme.typography.caption)
                                            .foregroundStyle(theme.color.textTertiary.color)
                                            .padding(.trailing, 4)
                                    }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                                    .foregroundStyle(theme.color.divider.color)
                                AxisValueLabel(format: .dateTime.month().day())
                                    .foregroundStyle(theme.color.textTertiary.color)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                    .foregroundStyle(theme.color.divider.color)
                                AxisValueLabel()
                                    .foregroundStyle(theme.color.textTertiary.color)
                            }
                        }
                        .frame(height: 220)
                    }
                }
                .padding(.horizontal, 16)

                // 인사이트
                let pts2 = trendUseCase.feedingTrend(
                    feedings: dashboardVM.sparkFeedings,
                    range: range,
                    anchorDate: dashboardVM.selectedDate
                )
                let avg2 = trendUseCase.average(of: pts2)
                TrendInsightCard(
                    insightText: trendUseCase.feedingInsight(avg: avg2, range: range),
                    tone: avg2 >= 450 ? .success : .warning
                )

                Spacer()
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("수유 상세")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - SleepDetailView

struct SleepDetailView: View {

    let dashboardVM: DashboardViewModel
    @State private var range: TrendRange = .week
    @Environment(\.theme) private var theme

    private let trendUseCase = ComputeTrendUseCase()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RangePicker(selection: $range)

                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("수면 시간 추이 (분)")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)

                        let points = trendUseCase.sleepTrend(
                            sleeps: dashboardVM.sparkSleeps,
                            range: range,
                            anchorDate: dashboardVM.selectedDate
                        )
                        let avg = trendUseCase.average(of: points)

                        Chart {
                            ForEach(points) { point in
                                AreaMark(
                                    x: .value("날짜", point.date, unit: .day),
                                    y: .value("분", point.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            theme.color.domainSleepSolid.color.opacity(0.6),
                                            theme.color.domainSleepSolid.color.opacity(0.05)
                                        ],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )

                                LineMark(
                                    x: .value("날짜", point.date, unit: .day),
                                    y: .value("분", point.value)
                                )
                                .foregroundStyle(theme.color.domainSleepSolid.color)
                                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                                PointMark(
                                    x: .value("날짜", point.date, unit: .day),
                                    y: .value("분", point.value)
                                )
                                .foregroundStyle(theme.color.domainSleepSolid.color)
                                .symbolSize(30)
                            }

                            if avg > 0 {
                                RuleMark(y: .value("평균", avg))
                                    .foregroundStyle(theme.color.textTertiary.color)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine().foregroundStyle(theme.color.divider.color)
                                AxisValueLabel(format: .dateTime.month().day())
                                    .foregroundStyle(theme.color.textTertiary.color)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                if let min = value.as(Double.self) {
                                    let h = Int(min) / 60; let m = Int(min) % 60
                                    AxisGridLine().foregroundStyle(theme.color.divider.color)
                                    AxisValueLabel {
                                        Text(h > 0 ? "\(h)h\(m > 0 ? "\(m)m" : "")" : "\(Int(min))m")
                                            .font(theme.typography.caption)
                                            .foregroundStyle(theme.color.textTertiary.color)
                                    }
                                }
                            }
                        }
                        .frame(height: 220)
                    }
                }
                .padding(.horizontal, 16)

                let pts2 = trendUseCase.sleepTrend(
                    sleeps: dashboardVM.sparkSleeps,
                    range: range,
                    anchorDate: dashboardVM.selectedDate
                )
                let avg2 = trendUseCase.average(of: pts2)
                TrendInsightCard(
                    insightText: trendUseCase.sleepInsight(avg: avg2, range: range),
                    tone: avg2 >= 840 ? .success : .info  // 신생아 14시간 권장
                )
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("수면 상세")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - DiaperDetailView

struct DiaperDetailView: View {

    let dashboardVM: DashboardViewModel
    @State private var range: TrendRange = .week
    @Environment(\.theme) private var theme

    private let trendUseCase = ComputeTrendUseCase()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RangePicker(selection: $range)

                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("기저귀 횟수 추이")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)

                        let points = trendUseCase.diaperTrend(
                            diapers: dashboardVM.sparkDiapers,
                            range: range,
                            anchorDate: dashboardVM.selectedDate
                        )
                        let avg = trendUseCase.average(of: points)

                        Chart {
                            ForEach(points) { point in
                                BarMark(
                                    x: .value("날짜", point.date, unit: .day),
                                    y: .value("횟수", point.value)
                                )
                                .foregroundStyle(theme.color.domainDiaperPeeSolid.color)
                                .cornerRadius(4)
                            }

                            if avg > 0 {
                                RuleMark(y: .value("평균", avg))
                                    .foregroundStyle(theme.color.textTertiary.color)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine().foregroundStyle(theme.color.divider.color)
                                AxisValueLabel(format: .dateTime.month().day())
                                    .foregroundStyle(theme.color.textTertiary.color)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(theme.color.divider.color)
                                AxisValueLabel().foregroundStyle(theme.color.textTertiary.color)
                            }
                        }
                        .frame(height: 220)
                    }
                }
                .padding(.horizontal, 16)

                let pts2 = trendUseCase.diaperTrend(
                    diapers: dashboardVM.sparkDiapers,
                    range: range,
                    anchorDate: dashboardVM.selectedDate
                )
                let avg2 = trendUseCase.average(of: pts2)
                TrendInsightCard(
                    insightText: trendUseCase.diaperInsight(avg: avg2, range: range),
                    tone: .info
                )
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("기저귀 상세")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - PlayDetailView

struct PlayDetailView: View {

    let dashboardVM: DashboardViewModel
    @State private var range: TrendRange = .week
    @Environment(\.theme) private var theme

    private let trendUseCase = ComputeTrendUseCase()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RangePicker(selection: $range)

                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("놀이 시간 추이 (분)")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)

                        let points = trendUseCase.playTrend(
                            plays: dashboardVM.sparkPlays,
                            range: range,
                            anchorDate: dashboardVM.selectedDate
                        )
                        let avg = trendUseCase.average(of: points)

                        Chart {
                            ForEach(points) { point in
                                BarMark(
                                    x: .value("날짜", point.date, unit: .day),
                                    y: .value("분", point.value)
                                )
                                .foregroundStyle(theme.color.domainPlaySolid.color)
                                .cornerRadius(4)
                            }

                            if avg > 0 {
                                RuleMark(y: .value("평균", avg))
                                    .foregroundStyle(theme.color.textTertiary.color)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine().foregroundStyle(theme.color.divider.color)
                                AxisValueLabel(format: .dateTime.month().day())
                                    .foregroundStyle(theme.color.textTertiary.color)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(theme.color.divider.color)
                                AxisValueLabel().foregroundStyle(theme.color.textTertiary.color)
                            }
                        }
                        .frame(height: 220)
                    }
                }
                .padding(.horizontal, 16)

                let pts2 = trendUseCase.playTrend(
                    plays: dashboardVM.sparkPlays,
                    range: range,
                    anchorDate: dashboardVM.selectedDate
                )
                let avg2 = trendUseCase.average(of: pts2)
                TrendInsightCard(
                    insightText: trendUseCase.playInsight(avg: avg2, range: range),
                    tone: .success
                )
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("놀이 상세")
        .navigationBarTitleDisplayMode(.large)
    }
}
