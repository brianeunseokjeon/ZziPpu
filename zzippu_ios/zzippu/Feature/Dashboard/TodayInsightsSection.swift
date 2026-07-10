// Feature/Dashboard/TodayInsightsSection.swift
// "오늘의 분석" 섹션 — DomainInsight 목록을 AnalysisCard + InsightRow 로 표시.
// Feature 레이어: Domain(DomainInsight) → DS(InsightRow) 매핑 담당(아이콘·값 포맷).
// 데이터 부족(noData)은 완곡 처리, 하단 면책 캡션 고정.

import SwiftUI

// MARK: - TodayInsightsSection

struct TodayInsightsSection: View {

    let insights: [DomainInsight]
    let headline: String

    @Environment(\.theme) private var theme

    var body: some View {
        AnalysisCard(
            title: "오늘의 분석",
            subtitle: headline.isEmpty ? nil : headline,
            disclaimer: "참고용이며 의학적 진단이 아니에요 · 출처 AAP·WHO·NSF/AASM"
        ) {
            if insights.isEmpty {
                // 가이드 로드 실패 등 — 완곡 안내(경보 아님).
                Text("기록이 더 쌓이면 분석해 드릴게요 📊")
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.color.textSecondary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                        InsightRow(
                            icon: Self.icon(for: insight.kind),
                            label: insight.title,
                            value: Self.valueText(for: insight),
                            statusTone: insight.tone,
                            statusText: insight.status.pillLabel,
                            comment: insight.comment
                        )
                        if index < insights.count - 1 {
                            Divider().overlay(theme.color.divider.color)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Kind → SF Symbol (Feature 매핑)

    static func icon(for kind: InsightKind) -> String {
        switch kind {
        case .feeding:   return "drop.fill"
        case .sleep:     return "moon.fill"
        case .pee:       return "drop"
        case .poop:      return "heart.fill"
        case .tummyTime: return "figure.play"
        }
    }

    // MARK: - 값 포맷 (지표별 단위)

    static func valueText(for insight: DomainInsight) -> String? {
        guard let actual = insight.actual else { return nil }
        switch insight.kind {
        case .feeding:
            return "\(Int(actual.rounded()))ml"
        case .sleep:
            return String(format: "%.1f시간", actual)
        case .pee, .poop:
            return "\(Int(actual.rounded()))회"
        case .tummyTime:
            return "\(Int(actual.rounded()))분"
        }
    }
}

// MARK: - Preview

#Preview("TodayInsightsSection — Light") {
    ScrollView {
        TodayInsightsSection(
            insights: [
                DomainInsight(kind: .feeding, status: .ok, title: "수유",
                              comment: "오늘 수유 720ml — 권장 600~720ml 안이에요 👍",
                              recommendedRange: 600...720, actual: 720, source: "AAP"),
                DomainInsight(kind: .sleep, status: .low, title: "수면",
                              comment: "하루 12.5시간 — 권장(14~17시간)보다 짧아요. 조금 더 재워볼까요?",
                              recommendedRange: 14...17, actual: 12.5, source: "NSF/AASM"),
                DomainInsight(kind: .pee, status: .ok, title: "소변",
                              comment: "하루 7회 — 충분히 잘 보고 있어요 👍",
                              recommendedRange: nil, actual: 7, source: "AAP"),
                DomainInsight(kind: .poop, status: .noData, title: "대변",
                              comment: "기록이 더 쌓이면 분석해 드릴게요 📊",
                              recommendedRange: nil, actual: nil, source: "AAP")
            ],
            headline: "대체로 좋아요. 수면을(를) 조금 더 살펴볼까요?"
        )
        .padding()
    }
    .environment(\.theme, .zzippu)
}

#Preview("TodayInsightsSection — Dark") {
    TodayInsightsSection(insights: [], headline: "")
        .padding()
        .background(Color.black)
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
