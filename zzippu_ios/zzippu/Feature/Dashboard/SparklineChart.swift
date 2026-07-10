// Feature/Dashboard/SparklineChart.swift
// 미니 스파크라인 차트 — 카드 내 7일 그래프 (축·범례 없음).
// 건강앱 스타일: 깔끔한 바·라인만.

import SwiftUI
import Charts

// MARK: - SparklineKind

enum SparklineKind {
    case bar
    case line
}

// MARK: - SparklineChart

struct SparklineChart: View {

    let points: [MetricPoint]
    let kind:   SparklineKind
    let color:  Color

    @Environment(\.theme) private var theme

    var body: some View {
        if points.isEmpty {
            Rectangle()
                .fill(theme.color.surfaceSunken.color)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Chart(points) { point in
                switch kind {
                case .bar:
                    BarMark(
                        x: .value("날짜", point.date, unit: .day),
                        y: .value("값", point.value)
                    )
                    .foregroundStyle(color)
                    .cornerRadius(2)
                case .line:
                    LineMark(
                        x: .value("날짜", point.date, unit: .day),
                        y: .value("값", point.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

                    AreaMark(
                        x: .value("날짜", point.date, unit: .day),
                        y: .value("값", point.value)
                    )
                    .foregroundStyle(color.opacity(0.15))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
        }
    }
}

private struct SparklineChartPreview: View {
    private let cal = Calendar.current
    private var points: [MetricPoint] {
        (0..<7).map { i in
            MetricPoint(date: cal.date(byAdding: .day, value: -i, to: .now)!, value: Double(i) * 50 + 100)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            SparklineChart(points: points, kind: .bar, color: .blue)
                .frame(width: 80, height: 40)
            SparklineChart(points: points, kind: .line, color: .purple)
                .frame(width: 80, height: 40)
        }
        .padding()
        .environment(\.theme, .zzippu)
    }
}

#Preview("SparklineChart") {
    SparklineChartPreview()
}
