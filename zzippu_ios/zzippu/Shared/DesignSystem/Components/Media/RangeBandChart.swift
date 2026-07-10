// Shared/DesignSystem/Components/Media/RangeBandChart.swift
// 권장 범위 밴드 오버레이 차트 헬퍼 — 추세 라인/바 + normalRange 음영 밴드.
// 성장 WHO 밴드(p3–p97, p15–p85, p50 파선)에도 재사용 가능하도록 일반화.
// DS-순수: Domain 비의존. (x: Date, y: Double) 포인트 + 밴드 스펙만 받는다.
// theme 토큰만 사용(raw 색 금지).

import SwiftUI
import Charts

// MARK: - 입력 타입

/// 차트 데이터 포인트 (DS-내부, Domain 비의존).
public struct RangeChartPoint: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let value: Double
    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

/// 음영 밴드 하나 (권장 구간 또는 WHO 백분위 구간).
public struct RangeBand: Identifiable, Sendable {
    public let id = UUID()
    public let lower: Double
    public let upper: Double
    public var opacity: Double     // 톤 위 음영 강도
    public init(lower: Double, upper: Double, opacity: Double = 0.15) {
        self.lower = lower
        self.upper = upper
        self.opacity = opacity
    }
}

public enum RangeChartKind: Sendable {
    case line
    case bar
}

// MARK: - RangeBandChart

public struct RangeBandChart: View {
    public let points: [RangeChartPoint]
    public let bands: [RangeBand]        // 겹쳐 그릴 밴드들(옅음→진함)
    public var referenceLine: Double?    // p50 등 파선 기준선
    public let kind: RangeChartKind
    public let tone: StatusTone          // 밴드·라인 색 톤
    public var showAxes: Bool

    public init(
        points: [RangeChartPoint],
        bands: [RangeBand] = [],
        referenceLine: Double? = nil,
        kind: RangeChartKind = .line,
        tone: StatusTone = .success,
        showAxes: Bool = true
    ) {
        self.points = points
        self.bands = bands
        self.referenceLine = referenceLine
        self.kind = kind
        self.tone = tone
        self.showAxes = showAxes
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        let tones = theme.color.status(tone: tone)
        let bandColor = tones.solid.color

        Chart {
            // 1) 밴드 음영 (y축 범위 RectangleMark — x 전 구간)
            ForEach(bands) { band in
                RectangleMark(
                    yStart: .value("하한", band.lower),
                    yEnd:   .value("상한", band.upper)
                )
                .foregroundStyle(bandColor.opacity(band.opacity))
            }

            // 2) 기준선(파선)
            if let ref = referenceLine {
                RuleMark(y: .value("기준", ref))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(theme.color.textTertiary.color)
            }

            // 3) 실측 데이터
            ForEach(points) { point in
                switch kind {
                case .line:
                    LineMark(
                        x: .value("날짜", point.date),
                        y: .value("값", point.value)
                    )
                    .foregroundStyle(bandColor)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("날짜", point.date),
                        y: .value("값", point.value)
                    )
                    .foregroundStyle(bandColor)
                    .symbolSize(20)
                case .bar:
                    BarMark(
                        x: .value("날짜", point.date, unit: .day),
                        y: .value("값", point.value)
                    )
                    .foregroundStyle(bandColor)
                    .cornerRadius(2)
                }
            }
        }
        .chartXAxis(showAxes ? .automatic : .hidden)
        .chartYAxis(showAxes ? .automatic : .hidden)
        .chartLegend(.hidden)
    }
}

// MARK: - Preview helpers

private struct RangeBandChartPreview: View {
    private let cal = Calendar.current
    private func series(_ base: Double, _ step: Double) -> [RangeChartPoint] {
        (0..<7).map { i in
            RangeChartPoint(
                date: cal.date(byAdding: .day, value: i - 6, to: .now)!,
                value: base + Double(i) * step
            )
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("수유 추세 + 권장 밴드").font(Theme.zzippu.typography.captionStrong)
            RangeBandChart(
                points: series(500, 40),
                bands: [RangeBand(lower: 600, upper: 720, opacity: 0.18)],
                kind: .line, tone: .success
            )
            .frame(height: 160)

            Text("성장 WHO 밴드(p3–p97 / p15–p85 / p50 파선)").font(Theme.zzippu.typography.captionStrong)
            RangeBandChart(
                points: series(6.2, 0.15),
                bands: [
                    RangeBand(lower: 5.5, upper: 9.0, opacity: 0.10),
                    RangeBand(lower: 6.4, upper: 8.0, opacity: 0.16)
                ],
                referenceLine: 7.2,
                kind: .line, tone: .info
            )
            .frame(height: 160)
        }
        .padding()
        .environment(\.theme, .zzippu)
    }
}

#Preview("RangeBandChart — Light") {
    RangeBandChartPreview()
}

#Preview("RangeBandChart — Dark") {
    RangeBandChartPreview()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
