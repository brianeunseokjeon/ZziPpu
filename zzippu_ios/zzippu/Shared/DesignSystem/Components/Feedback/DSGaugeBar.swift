// Shared/DesignSystem/Components/Feedback/DSGaugeBar.swift
// 수유량 게이지 바.
// track=surfaceSunken, normalBand=statusSuccessBg 오버레이, height 12, pill.
// tone→fill: status.{tone}.solid.

import SwiftUI

// MARK: - DSGaugeBar

/// `fillRatio`: 0.0~1.0+ (초과분 스케일은 호출자 몫).
/// `normalRange`: 0.0~1.0 범위의 ClosedRange<Double> — 권장 구간 강조 오버레이.
/// `tone`: StatusTone → fill 색 결정.
public struct DSGaugeBar: View {
    public let fillRatio:   Double            // 0.0 ~ 1.0 (clamp 후 표시)
    public let normalRange: ClosedRange<Double>?  // e.g. 0.3...0.8
    public let tone:        StatusTone

    public init(
        fillRatio:   Double,
        normalRange: ClosedRange<Double>? = nil,
        tone:        StatusTone = .success
    ) {
        self.fillRatio   = fillRatio
        self.normalRange = normalRange
        self.tone        = tone
    }

    private let barHeight: CGFloat = 12

    @Environment(\.theme) private var theme

    public var body: some View {
        GeometryReader { geo in
            let width  = geo.size.width
            let ratio  = max(0, min(1, fillRatio))
            let tones  = theme.color.status(tone: tone)

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(theme.color.surfaceSunken.color)
                    .frame(height: barHeight)

                // Normal band overlay
                if let range = normalRange {
                    let bandX     = range.lowerBound * width
                    let bandWidth = (range.upperBound - range.lowerBound) * width
                    RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                        .fill(theme.color.statusSuccessBg.color)
                        .frame(width: max(0, bandWidth), height: barHeight)
                        .offset(x: bandX)
                }

                // Fill
                Capsule()
                    .fill(tones.solid.color)
                    .frame(width: max(0, ratio * width), height: barHeight)
            }
        }
        .frame(height: barHeight)
    }
}

// MARK: - Preview

#Preview("DSGaugeBar") {
    VStack(spacing: 20) {
        Text("success (적정)").font(Theme.zzippu.typography.captionStrong)
        DSGaugeBar(fillRatio: 0.65, normalRange: 0.4...0.8, tone: .success)

        Text("warning (부족)").font(Theme.zzippu.typography.captionStrong)
        DSGaugeBar(fillRatio: 0.25, normalRange: 0.4...0.8, tone: .warning)

        Text("danger (과다)").font(Theme.zzippu.typography.captionStrong)
        DSGaugeBar(fillRatio: 0.95, normalRange: 0.4...0.8, tone: .danger)

        Text("normalBand 없음").font(Theme.zzippu.typography.captionStrong)
        DSGaugeBar(fillRatio: 0.5, tone: .success)
    }
    .padding()
    .environment(\.theme, .zzippu)
}
