// Feature/Dashboard/MetricCard.swift
// 건강앱 스타일 메트릭 카드: 큰 숫자 + 서브텍스트 + 미니 스파크라인.

import SwiftUI
import Charts

struct MetricCard: View {

    let title:    String
    let value:    String
    let subValue: String
    let symbol:   String          // SF Symbol
    let color:    Color
    let points:   [MetricPoint]
    let sparkKind: SparklineKind
    let onTap:   () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // 상단: 아이콘 + 타이틀
                HStack(spacing: 6) {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                    Text(title)
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.color.textTertiary.color)
                }

                Spacer().frame(height: 10)

                // 큰 숫자
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.color.textPrimary.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if !subValue.isEmpty {
                    Text(subValue)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textTertiary.color)
                        .padding(.top, 2)
                }

                Spacer().frame(height: 12)

                // 미니 스파크라인
                SparklineChart(points: points, kind: sparkKind, color: color)
                    .frame(height: 36)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard(style: .interactive)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 성장 카드 (스파크라인 없음, 큰 수치만)

struct GrowthMetricCard: View {

    let weight: String
    let height: String
    let onTap:  () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // 상단
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.color.primary.color)
                    Text("성장")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.color.textTertiary.color)
                }

                Spacer().frame(height: 10)

                HStack(alignment: .bottom, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("체중")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textTertiary.color)
                        Text(weight)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.color.textPrimary.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("키")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textTertiary.color)
                        Text(height)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.color.textPrimary.color)
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard(style: .interactive)
        }
        .buttonStyle(.plain)
    }
}

private struct MetricCardPreview: View {
    private let cal = Calendar.current
    private var points: [MetricPoint] {
        (0..<7).map { i in
            MetricPoint(date: cal.date(byAdding: .day, value: -i, to: .now)!, value: Double(i) * 40 + 60)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MetricCard(
                    title: "수유", value: "680ml", subValue: "5회",
                    symbol: "drop.fill", color: .blue,
                    points: points, sparkKind: .bar,
                    onTap: {}
                )
                MetricCard(
                    title: "수면", value: "14시간", subValue: "3회",
                    symbol: "moon.fill", color: .indigo,
                    points: points, sparkKind: .line,
                    onTap: {}
                )
            }
            HStack(spacing: 12) {
                MetricCard(
                    title: "기저귀", value: "8회", subValue: "소5 대3",
                    symbol: "heart.fill", color: .yellow,
                    points: points, sparkKind: .bar,
                    onTap: {}
                )
                GrowthMetricCard(weight: "4.2kg", height: "55.0cm", onTap: {})
            }
        }
        .padding()
        .environment(\.theme, .zzippu)
    }
}

#Preview("MetricCard") {
    MetricCardPreview()
}
