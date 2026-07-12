// Feature/Dashboard/DashboardSummaryCards.swift
// 다음 수유 예측 카드 + 수유 적정량 게이지 카드.

import SwiftUI

// MARK: - NextFeedingCard

struct NextFeedingCard: View {

    let prediction: FeedingPrediction

    @Environment(\.theme) private var theme

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                // 다음 수유 예상 — 아이콘 36 + 시각 title(18) 인라인 강조
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.color.primaryTint.color)
                            .frame(width: 36, height: 36)
                        Image(systemName: "clock.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(theme.color.primary.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("다음 수유 예상")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textSecondary.color)

                        if let nextAt = prediction.nextFeedingAt {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(nextAt, format: .dateTime.hour().minute())
                                    .font(theme.typography.title)
                                    .foregroundStyle(theme.color.textPrimary.color)
                                if let sub = feedingSubText {
                                    Text(sub)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.color.textTertiary.color)
                                }
                            }
                        } else {
                            Text("예측 없음")
                                .font(theme.typography.headline)
                                .foregroundStyle(theme.color.textTertiary.color)
                        }
                    }

                    Spacer()

                    if prediction.nextFeedingAt != nil {
                        DSStatusPill(tone: .info, text: "예측")
                    }
                }

                // 다음 수면 예상 — 같은 카드에 caption 한 줄 병합(웹 정합)
                if let sleepAt = prediction.nextSleepAt {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.color.domainSleepSolid.color)
                        Text("다음 수면 예상")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textSecondary.color)
                        Text(sleepAt, format: .dateTime.hour().minute())
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textPrimary.color)
                    }
                    .padding(.leading, 48)
                }
            }
        }
    }

    /// "약 N분 후 · 평소 M시간 간격" 보조 캡션.
    private var feedingSubText: String? {
        var parts: [String] = []
        if let next = prediction.nextFeedingAt {
            let mins = Int(next.timeIntervalSince(.now) / 60)
            if mins > 0 { parts.append("약 \(mins)분 후") }
            else { parts.append("수유 시간이에요") }
        }
        if let interval = prediction.feedingIntervalMinutes {
            let h = interval / 60; let m = interval % 60
            parts.append(h > 0 ? "평소 \(h)시간 \(m)분 간격" : "평소 \(m)분 간격")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
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
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("오늘 수유량")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    Spacer()
                    DSStatusPill(tone: adequacyTone, text: adequacyLabel)
                }

                HStack(alignment: .center, spacing: 20) {
                    // 대표 지표 링 — 화면 유일 display36(중앙 총 ml)
                    DSRingGauge(
                        ratio: fillRatio,
                        normalRange: normalRange,
                        tone: adequacyTone,
                        centerText: "\(totalMl)",
                        centerCaption: "ml",
                        size: 132,
                        lineWidth: 14
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        if let lo = recommendedMin, let hi = recommendedMax {
                            Text("권장 \(lo)~\(hi)ml")
                                .font(theme.typography.body)
                                .foregroundStyle(theme.color.textPrimary.color)
                            Text("체중 기반 · AAP")
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.color.textTertiary.color)
                        } else {
                            Text("체중을 등록하면 AAP 권장과 비교해 드려요")
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.color.textTertiary.color)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    /// DSRingGauge 계약: ratio = 총량 / 권장상한 (링이 내부에서 1.3 clamp·매핑).
    private var fillRatio: Double {
        guard let hi = recommendedMax, hi > 0 else { return 0 }
        return Double(totalMl) / Double(hi)
    }

    /// 권장 밴드(권장상한 기준 정규화). lo/hi ... 1.0.
    private var normalRange: ClosedRange<Double>? {
        guard let lo = recommendedMin, let hi = recommendedMax, hi > 0 else { return nil }
        return (Double(lo) / Double(hi)) ... 1.0
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
