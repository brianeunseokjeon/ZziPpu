// Feature/Dashboard/GrowthAssessmentSection.swift
// 성장 판정 섹션 — 기대 평균(p50) 요약 라인 + 5카테고리 배지 + 완곡·비진단 문구.
// 클린아키텍처: 판정(카테고리)은 Domain, 색·표현은 여기(View)에서 매핑.
// 다크·큰글씨·접근성: 색 + 텍스트 병기(색만으로 의미 전달 금지).

import SwiftUI

// MARK: - Category → 색 톤 매핑 (View 전용)

extension GrowthPercentileCategory {
    /// DSStatusPill 톤. Domain은 색을 모르므로 표현 레이어에서 매핑.
    var statusTone: StatusTone {
        switch self {
        case .veryLow:  return .danger    // 스크리닝 하한 — 상담 권유
        case .low:      return .warning
        case .normal:   return .success
        case .high:     return .warning
        case .veryHigh: return .danger    // 스크리닝 상한 — 상담 권유
        }
    }
}

// MARK: - GrowthAssessmentSection

/// 기대 평균 + 배지 + 보조 문구를 묶은 카드 내부 섹션.
/// 표시 조건(성별·실측·범위)은 상위(GrowthDetailView)에서 이미 가드하고 값만 주입.
struct GrowthAssessmentSection: View {

    /// "생후 N개월 남아 평균 체중 ≈ 6.4kg" 요약(없으면 숨김).
    let expectedSummary: String?
    /// 5카테고리 판정(없으면 배지·보조문구 숨김).
    let category: GrowthPercentileCategory?
    /// 미숙아 주의 문구 노출 여부.
    let showsPrematureNote: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let expectedSummary {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "figure.child")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textTertiary.color)
                        .accessibilityHidden(true)
                    Text(expectedSummary)
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let category {
                DSStatusPill(tone: category.statusTone, text: category.badgeLabel())
                    .accessibilityLabel(Text(category.badgeLabel()))

                Text(category.supportingText)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if showsPrematureNote {
                DSDisclaimerCaption(
                    "미숙아(이른둥이)는 교정연령 기준으로 해석해야 정확해요(보통 24개월까지).",
                    showIcon: true
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

private struct AssessmentPreviewList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(GrowthPercentileCategory.allCases, id: \.self) { cat in
                GrowthAssessmentSection(
                    expectedSummary: "생후 6개월 남아 평균 체중 ≈ 7.9kg",
                    category: cat,
                    showsPrematureNote: cat == .veryLow
                )
                Divider()
            }
            GrowthAssessmentSection(
                expectedSummary: "생후 3개월 여아 평균 키 ≈ 59.8cm",
                category: nil,
                showsPrematureNote: false
            )
        }
        .padding()
    }
}

#Preview("GrowthAssessment — Light") {
    AssessmentPreviewList()
        .environment(\.theme, .zzippu)
}

#Preview("GrowthAssessment — Dark") {
    AssessmentPreviewList()
        .background(Color.black)
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
