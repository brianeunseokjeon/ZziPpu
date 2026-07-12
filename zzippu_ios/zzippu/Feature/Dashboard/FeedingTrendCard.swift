// Feature/Dashboard/FeedingTrendCard.swift
// "수유량 추세" 카드 — 7일/14일 토글 + DSTrendBarChart. 웹 TrendsDashboard(수유) 정합.
// Feature는 Domain(FeedingTrendDay) → DS(DSTrendPoint, theme 색 주입)로 매핑만. DS는 도메인 비의존.

import SwiftUI

struct FeedingTrendCard: View {

    /// 현재 토글 기준 일별 수유량(요일 라벨·빈날 nil).
    let days: [FeedingTrendDay]
    /// 선택 기간(7/14).
    let dayCount: Int
    /// 권장선(min/max ml). 없으면 선 생략.
    let guideline: (min: Double, max: Double)?
    /// 토글 변경 콜백.
    let onSelectDayCount: (Int) -> Void

    @Environment(\.theme) private var theme

    // Domain → DS 매핑(theme 도메인색 주입).
    private var points: [DSTrendPoint] {
        days.map { d in
            DSTrendPoint(date: d.date, value: d.totalMl, label: d.weekdayLabel)
        }
    }

    private var hasData: Bool { days.contains { $0.totalMl != nil } }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                header

                if hasData {
                    DSTrendBarChart(
                        points: points,
                        color: theme.color.domainFeedingFormulaSolid.color,
                        unit: "ml",
                        guidelineMin: guideline?.min,
                        guidelineMax: guideline?.max
                    )
                } else {
                    emptyState
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("수유량 추세")
                .font(theme.typography.headlineStrong)
                .foregroundStyle(theme.color.textPrimary.color)

            Spacer(minLength: 8)

            rangeToggle
        }
    }

    // 웹 TrendRangeToggle: 7일/14일 세그먼트(선택=진하게).
    private var rangeToggle: some View {
        HStack(spacing: 6) {
            ForEach([7, 14], id: \.self) { count in
                DSChip(
                    label: "\(count)일",
                    isSelected: dayCount == count,
                    variant: .selectable,
                    onTap: { onSelectDayCount(count) }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("아직 추세를 보여드릴 기록이 없어요")
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textSecondary.color)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
}

// MARK: - Preview

private struct FeedingTrendCardPreview: View {
    @State private var count = 7

    private func sample(_ days: Int) -> [FeedingTrendDay] {
        let cal = Calendar.kst
        let sym = ["일", "월", "화", "수", "목", "금", "토"]
        return (0..<days).reversed().map { back in
            let date = cal.date(byAdding: .day, value: -back, to: .now)!
            let w = cal.component(.weekday, from: date) - 1
            let value: Double? = back == 4 ? nil : Double(560 + (back * 41) % 260)
            return FeedingTrendDay(date: date, totalMl: value, weekdayLabel: sym[w])
        }
    }

    var body: some View {
        ScrollView {
            FeedingTrendCard(
                days: sample(count),
                dayCount: count,
                guideline: (min: 550, max: 780),
                onSelectDayCount: { count = $0 }
            )
            .padding()
        }
    }
}

#Preview("FeedingTrendCard — light") {
    FeedingTrendCardPreview()
        .environment(\.theme, .zzippu)
}

#Preview("FeedingTrendCard — dark") {
    FeedingTrendCardPreview()
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
