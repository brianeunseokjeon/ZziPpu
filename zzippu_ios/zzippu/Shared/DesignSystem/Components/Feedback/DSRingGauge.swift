// Shared/DesignSystem/Components/Feedback/DSRingGauge.swift
// 단일 진행/적정도 링 게이지 — 권장 밴드 대비 채움.
// Domain 비의존: ratio·normalRange·tone·centerText만 주입. theme 토큰만 사용.
// ② 오늘 수유량 대표 지표(링형), 카드 미니 재사용.

import SwiftUI

// MARK: - DSRingGauge

public struct DSRingGauge: View {

    /// 채움 비율(0.0~). 권장 상한 기준 정규화는 호출자 몫. 1.3(=130%)까지 표시 clamp.
    public let ratio: Double
    /// 링 위 권장 구간 강조(0.0~1.0 정규화). nil이면 밴드 생략.
    public let normalRange: ClosedRange<Double>?
    public let tone: StatusTone
    public let centerText: String?
    public let centerCaption: String?
    public let size: CGFloat
    public let lineWidth: CGFloat

    public init(
        ratio: Double,
        normalRange: ClosedRange<Double>? = nil,
        tone: StatusTone = .success,
        centerText: String? = nil,
        centerCaption: String? = nil,
        size: CGFloat = 132,
        lineWidth: CGFloat = 14
    ) {
        self.ratio = ratio
        self.normalRange = normalRange
        self.tone = tone
        self.centerText = centerText
        self.centerCaption = centerCaption
        self.size = size
        self.lineWidth = lineWidth
    }

    @Environment(\.theme) private var theme

    /// 게이지는 하단 40°를 비운 270° 아크. 0=하단좌 → 시계방향.
    private let startAngle: Double = 135
    private let sweep: Double = 270

    private var clampedRatio: Double { max(0, min(1.3, ratio)) }
    /// 표시 비율은 트랙(정규화 축)에 맞춰 130%까지 → 아크 fraction.
    private var fillFraction: Double { min(clampedRatio / 1.3, 1.0) }

    public var body: some View {
        let tones = theme.color.status(tone: tone)
        ZStack {
            // 트랙
            RingArc(startAngle: startAngle, sweep: sweep, fraction: 1.0, inset: lineWidth / 2)
                .stroke(theme.color.surfaceSunken.color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // 권장 밴드(정규화 0~1 → 130% 축에 매핑)
            if let range = normalRange {
                let lo = min(range.lowerBound / 1.3, 1.0)
                let hi = min(range.upperBound / 1.3, 1.0)
                RingArc(startAngle: startAngle + sweep * lo,
                        sweep: sweep * (hi - lo),
                        fraction: 1.0, inset: lineWidth / 2)
                    .stroke(theme.color.statusSuccessBg.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }

            // 채움
            RingArc(startAngle: startAngle, sweep: sweep, fraction: fillFraction, inset: lineWidth / 2)
                .stroke(tones.solid.color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // 중앙 라벨
            VStack(spacing: 2) {
                if let centerText {
                    Text(centerText)
                        .font(theme.typography.display)
                        .dsDynamicTypeCap()
                        .foregroundStyle(theme.color.textPrimary.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                if let centerCaption {
                    Text(centerCaption)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textSecondary.color)
                }
            }
            .padding(.horizontal, lineWidth)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - RingArc Shape

private struct RingArc: Shape {
    let startAngle: Double   // degrees
    let sweep: Double        // degrees (full track span)
    let fraction: Double     // 0...1 of sweep to draw
    let inset: CGFloat       // half stroke width, keeps ring inside frame

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 - inset
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(startAngle + sweep * max(0, min(1, fraction))),
            clockwise: false
        )
        return p
    }
}

// MARK: - Preview

private struct DSRingGaugePreview: View {
    var body: some View {
        HStack(spacing: 24) {
            DSRingGauge(ratio: 0.72, normalRange: 0.64...0.77, tone: .success,
                        centerText: "380", centerCaption: "ml · 적정")
            DSRingGauge(ratio: 0.35, normalRange: 0.64...0.77, tone: .warning,
                        centerText: "180", centerCaption: "ml · 부족", size: 100, lineWidth: 11)
        }
        .padding()
    }
}

#Preview("DSRingGauge — light") {
    DSRingGaugePreview()
        .environment(\.theme, .zzippu)
}

#Preview("DSRingGauge — dark") {
    DSRingGaugePreview()
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
