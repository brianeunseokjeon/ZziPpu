// Feature/Dashboard/DashboardSummaryCards.swift
// 다음 수유 예측 카드 + 수유 적정량 게이지 카드.

import SwiftUI

// MARK: - NextFeedingCard

struct NextFeedingCard: View {

    let prediction: FeedingPrediction

    @Environment(\.theme) private var theme

    var body: some View {
        CardContainer {
            HStack(alignment: .center, spacing: 16) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(theme.color.primaryTint.color)
                        .frame(width: 48, height: 48)
                    Image(systemName: "clock.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.color.primary.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("다음 수유 예상")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textSecondary.color)

                    if let nextAt = prediction.nextFeedingAt {
                        Text(nextAt, format: .dateTime.hour().minute())
                            .font(theme.typography.display)
                            .dsDynamicTypeCap()
                            .foregroundStyle(theme.color.textPrimary.color)
                    } else {
                        Text("예측 없음")
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.color.textTertiary.color)
                    }

                    if let interval = prediction.feedingIntervalMinutes {
                        let h = interval / 60; let m = interval % 60
                        let txt = h > 0 ? "\(h)시간 \(m)분 간격" : "\(m)분 간격"
                        Text(txt)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textTertiary.color)
                    }
                }

                Spacer()

                if prediction.nextFeedingAt != nil {
                    DSStatusPill(tone: .info, text: "예측")
                }
            }
        }
    }
}

// MARK: - FeedingAdequacyCard

struct FeedingAdequacyCard: View {

    /// 오늘 총 수유량 (ml)
    let totalMl: Int
    /// 체중 기반 권장 범위(ml) — 가이드(AAP 150~180ml/kg) 연동. 없으면(체중 미등록) 비교 생략.
    let recommendedRange: ClosedRange<Double>?

    init(totalMl: Int, recommendedRange: ClosedRange<Double>? = nil) {
        self.totalMl = totalMl
        self.recommendedRange = recommendedRange
    }

    @Environment(\.theme) private var theme

    private var recommendedMin: Int? { recommendedRange.map { Int($0.lowerBound) } }
    private var recommendedMax: Int? { recommendedRange.map { Int($0.upperBound) } }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("오늘 수유량")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    Spacer()
                    DSStatusPill(tone: adequacyTone, text: adequacyLabel)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(totalMl)")
                        .font(theme.typography.display)
                        .dsDynamicTypeCap()
                        .foregroundStyle(theme.color.textPrimary.color)
                    Text("ml")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.color.textSecondary.color)
                }

                DSGaugeBar(
                    fillRatio: fillRatio,
                    normalRange: normalRange,
                    tone: adequacyTone
                )

                if let lo = recommendedMin, let hi = recommendedMax {
                    Text("권장 \(lo)~\(hi)ml (체중 기반 · AAP)")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textTertiary.color)
                } else {
                    Text("체중을 등록하면 AAP 권장과 비교해 드려요")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textTertiary.color)
                }
            }
        }
    }

    private var fillRatio: Double {
        guard let hi = recommendedMax, hi > 0 else { return 0 }
        return min(Double(totalMl) / Double(hi), 1.3)  // 130%까지 표시
    }

    private var normalRange: ClosedRange<Double>? {
        guard let lo = recommendedMin, let hi = recommendedMax, hi > 0 else { return nil }
        let maxVal = Double(hi) * 1.3
        return Double(lo) / maxVal ... Double(hi) / maxVal
    }

    private var adequacyTone: StatusTone {
        guard let lo = recommendedMin, let hi = recommendedMax else { return .info }
        if totalMl < lo { return .warning }
        if totalMl > hi { return .info }
        return .success
    }

    private var adequacyLabel: String {
        if totalMl == 0 { return "기록 없음" }
        guard let lo = recommendedMin, let hi = recommendedMax else { return "정보 없음" }
        if totalMl < lo { return "권장보다 적음" }
        if totalMl > hi { return "권장 초과" }
        return "적정"
    }
}

#Preview("DashboardSummaryCards") {
    ScrollView {
        VStack(spacing: 12) {
            NextFeedingCard(prediction: FeedingPrediction(
                lastFeedingAt: .now.addingTimeInterval(-7200),
                nextFeedingAt: .now.addingTimeInterval(600),
                feedingIntervalMinutes: 180,
                feedingBasedOn: 5,
                lastSleepEndedAt: nil, nextSleepAt: nil,
                awakeWindowMinutes: nil, sleepBasedOn: 0
            ))

            FeedingAdequacyCard(totalMl: 380, recommendedRange: 525...630)
            FeedingAdequacyCard(totalMl: 560, recommendedRange: 525...630)
            FeedingAdequacyCard(totalMl: 300)  // 체중 미등록 → 비교 생략
        }
        .padding()
    }
    .environment(\.theme, .zzippu)
}
