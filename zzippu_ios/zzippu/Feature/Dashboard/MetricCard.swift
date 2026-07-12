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
    /// 비중 도넛 세그먼트. nil/빈 배열이면 스파크라인으로 폴백(비추이 카드만 도넛 사용).
    let donutSegments: [DSDonutSegment]?
    let donutCenter:   (text: String, caption: String)?
    let onTap:   () -> Void

    init(
        title: String, value: String, subValue: String, symbol: String,
        color: Color, points: [MetricPoint], sparkKind: SparklineKind,
        donutSegments: [DSDonutSegment]? = nil,
        donutCenter: (text: String, caption: String)? = nil,
        onTap: @escaping () -> Void
    ) {
        self.title = title; self.value = value; self.subValue = subValue
        self.symbol = symbol; self.color = color; self.points = points
        self.sparkKind = sparkKind
        self.donutSegments = donutSegments; self.donutCenter = donutCenter
        self.onTap = onTap
    }

    @Environment(\.theme) private var theme

    private var usesDonut: Bool { (donutSegments?.isEmpty == false) }

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

                if usesDonut, let segments = donutSegments {
                    // 비중 도넛(수유 분유/모유, 기저귀 소/대) — 중앙에 대표값
                    HStack(alignment: .center, spacing: 10) {
                        DSDonutChart(
                            segments: segments,
                            centerText: donutCenter?.text ?? value,
                            centerCaption: donutCenter?.caption,
                            size: .sm
                        )
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(segments) { seg in
                                HStack(spacing: 5) {
                                    Circle().fill(seg.color).frame(width: 7, height: 7)
                                    Text(seg.label)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.color.textSecondary.color)
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    // 값 (title 18 — 화면당 display36 1개 원칙, 그리드는 title로 강등)
                    Text(value)
                        .font(theme.typography.title)
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

                    // 미니 스파크라인(추이 카드 — 수면·놀이)
                    SparklineChart(points: points, kind: sparkKind, color: color)
                        .frame(height: 36)
                }
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
                            .font(theme.typography.headline)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .foregroundStyle(theme.color.textPrimary.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("키")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textTertiary.color)
                        Text(height)
                            .font(theme.typography.headline)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
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
