// Shared/DesignSystem/Components/Feedback/DSTrendBarChart.swift
// 일별 추세 막대 차트 — Swift Charts BarMark(상단 라운드). 웹 TrendChart.tsx 정합.
// Domain 비의존: 데이터(날짜/값/라벨) + 색(theme Color 주입) + 옵션만 받는다. raw 색 금지.
//
// 웹 스펙 재현:
//   • height ≈ 120, 막대 상단 모서리 라운드(radius 4)
//   • 색: 일반=도메인색 / 오늘(마지막)=진하게(−40 RGB) / 데이터없음=흐리게(30%)
//   • 권장선: min/max 두 개 점선(4-4, 도메인색 50%) — RuleMark
//   • x축=요일 라벨(fontSize 10, gray-400, tick/axis line 없음, 7일=매 라벨/14일=격일)
//   • y축 작게(gray-400, width 28)
//   • 수평 그리드 점선(3-3, #f0f0f0)

import SwiftUI
import Charts

// MARK: - DSTrendPoint

/// 추세 막대 한 점. value=nil이면 데이터 없음(흐리게 렌더).
public struct DSTrendPoint: Identifiable, Equatable {
    public let id: String
    public let date: Date
    public let value: Double?
    public let label: String

    public init(id: String = UUID().uuidString, date: Date, value: Double?, label: String) {
        self.id = id
        self.date = date
        self.value = value
        self.label = label
    }
}

// MARK: - DSTrendBarChart

public struct DSTrendBarChart: View {

    public let points: [DSTrendPoint]
    /// 도메인색(막대 기본 색). theme 토큰 Color 주입 — DS는 도메인 비의존.
    public let color: Color
    public let unit: String
    public let guidelineMin: Double?
    public let guidelineMax: Double?
    public let todayHighlight: Bool

    public init(
        points: [DSTrendPoint],
        color: Color,
        unit: String = "",
        guidelineMin: Double? = nil,
        guidelineMax: Double? = nil,
        todayHighlight: Bool = true
    ) {
        self.points = points
        self.color = color
        self.unit = unit
        self.guidelineMin = guidelineMin
        self.guidelineMax = guidelineMax
        self.todayHighlight = todayHighlight
    }

    @Environment(\.theme) private var theme

    // 웹 x축/그리드/축 라벨 색: gray-400 (#9CA3AF). theme.textTertiary로 매핑.
    private var axisLabelColor: Color { theme.color.textTertiary.color }
    // 웹 수평 그리드: #f0f0f0. 다크 대응 위해 border 토큰 사용.
    private var gridColor: Color { theme.color.textTertiary.color.opacity(0.25) }

    private var lastIndex: Int { points.count - 1 }

    /// 오늘(마지막) 막대 — 웹 darkenHex(−40 RGB).
    private var todayColor: Color { darken(color, by: 40.0 / 255.0) }
    /// 데이터 없음 — 웹 30% 투명.
    private var faintColor: Color { color.opacity(0.3) }

    private var hasGuideline: Bool { guidelineMin != nil && guidelineMax != nil }

    /// x축 라벨 노출 간격: 7일 이하=매 라벨, 그 이상(14)=격일.
    private var showsEveryOtherLabel: Bool { points.count > 7 }

    private func fill(for index: Int) -> Color {
        let p = points[index]
        if p.value == nil { return faintColor }
        if todayHighlight && index == lastIndex { return todayColor }
        return color
    }

    public var body: some View {
        Chart {
            // 권장선(점선) — 막대보다 먼저 그려 막대가 위로.
            if hasGuideline, let gMax = guidelineMax {
                RuleMark(y: .value("권장 최대", gMax))
                    .foregroundStyle(color.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            if hasGuideline, let gMin = guidelineMin {
                RuleMark(y: .value("권장 최소", gMin))
                    .foregroundStyle(color.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }

            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                BarMark(
                    x: .value("요일", point.label),
                    y: .value("값", point.value ?? 0)
                )
                .foregroundStyle(fill(for: index))
                .cornerRadius(4, style: .continuous)
            }
        }
        // 수평 그리드 점선(3-3) + y축 작게(gray-400, width 28).
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(gridColor)
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(axisLabelColor)
            }
        }
        // x축=요일 라벨(fontSize 10, gray-400, tick/axis line 없음, 7=매/14=격일).
        .chartXAxis {
            AxisMarks { value in
                if shouldShowXLabel(at: value.index) {
                    AxisValueLabel(centered: true) {
                        if let label: String = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 10))
                                .foregroundStyle(axisLabelColor)
                        }
                    }
                }
            }
        }
        .frame(height: 120)
    }

    private func shouldShowXLabel(at index: Int) -> Bool {
        guard showsEveryOtherLabel else { return true }
        // 14일: 격일 노출. 마지막(오늘)은 항상 노출.
        if index == lastIndex { return true }
        return index % 2 == 0
    }
}

// MARK: - Color darken (웹 darkenHex −40 RGB 정합)

private func darken(_ color: Color, by amount: Double) -> Color {
    #if canImport(UIKit)
    let ui = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return color }
    return Color(
        red: max(0, Double(r) - amount),
        green: max(0, Double(g) - amount),
        blue: max(0, Double(b) - amount),
        opacity: Double(a)
    )
    #else
    return color
    #endif
}

// MARK: - Preview

private struct DSTrendBarChartPreview: View {
    @Environment(\.theme) private var theme

    private func sample(days: Int) -> [DSTrendPoint] {
        let cal = Calendar.kst
        let weekday = ["일", "월", "화", "수", "목", "금", "토"]
        return (0..<days).reversed().map { back in
            let date = cal.date(byAdding: .day, value: -back, to: .now)!
            let w = cal.component(.weekday, from: date) - 1
            // 일부 날은 데이터 없음(흐리게) 확인용.
            let value: Double? = (back == 3 || back == 6) ? nil : Double(500 + (back * 37) % 300)
            return DSTrendPoint(date: date, value: value, label: weekday[w])
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("7일 (권장선 있음)").font(theme.typography.caption)
                DSTrendBarChart(
                    points: sample(days: 7),
                    color: theme.color.domainFeedingFormulaSolid.color,
                    unit: "ml",
                    guidelineMin: 550,
                    guidelineMax: 750
                )

                Text("14일 (격일 라벨)").font(theme.typography.caption)
                DSTrendBarChart(
                    points: sample(days: 14),
                    color: theme.color.domainFeedingFormulaSolid.color,
                    unit: "ml"
                )
            }
            .padding()
        }
    }
}

#Preview("DSTrendBarChart — light") {
    DSTrendBarChartPreview()
        .environment(\.theme, .zzippu)
}

#Preview("DSTrendBarChart — dark") {
    DSTrendBarChartPreview()
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
