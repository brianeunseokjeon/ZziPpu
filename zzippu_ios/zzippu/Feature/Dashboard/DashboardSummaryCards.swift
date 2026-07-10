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
                            .font(.system(size: 28, weight: .bold, design: .rounded))
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
    /// 신생아 가이드라인: 150ml/kg/day, 평균 3.5kg 기준 약 525ml
    /// 실제 가이드라인 밴드: 450~600ml (하한~상한)
    private let recommendedMin: Int = 450
    private let recommendedMax: Int = 600

    @Environment(\.theme) private var theme

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
                        .font(.system(size: 32, weight: .bold, design: .rounded))
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

                Text("권장 \(recommendedMin)~\(recommendedMax)ml (신생아 평균 기준)")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textTertiary.color)
            }
        }
    }

    private var fillRatio: Double {
        guard recommendedMax > 0 else { return 0 }
        return min(Double(totalMl) / Double(recommendedMax), 1.3)  // 130%까지 표시
    }

    private var normalRange: ClosedRange<Double> {
        let maxVal = Double(recommendedMax) * 1.3
        guard maxVal > 0 else { return 0...1 }
        return Double(recommendedMin) / maxVal ... Double(recommendedMax) / maxVal
    }

    private var adequacyTone: StatusTone {
        if totalMl < recommendedMin { return .warning }
        if totalMl > recommendedMax { return .info }
        return .success
    }

    private var adequacyLabel: String {
        if totalMl == 0 { return "기록 없음" }
        if totalMl < recommendedMin { return "권장보다 적음" }
        if totalMl > recommendedMax { return "권장 초과" }
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

            FeedingAdequacyCard(totalMl: 380)
            FeedingAdequacyCard(totalMl: 520)
        }
        .padding()
    }
    .environment(\.theme, .zzippu)
}
