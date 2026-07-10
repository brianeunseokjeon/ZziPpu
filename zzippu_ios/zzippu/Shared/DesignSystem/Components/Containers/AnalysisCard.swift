// Shared/DesignSystem/Components/Containers/AnalysisCard.swift
// "오늘의 분석" 류 섹션 카드 — DSCard(CardContainer) 래핑 + 헤더 + 콘텐츠 슬롯 + 면책 캡션.
// Open-Closed: 콘텐츠는 @ViewBuilder 슬롯(InsightRow 목록 등 자유 조합).
// theme 토큰만 사용.

import SwiftUI

public struct AnalysisCard<Content: View>: View {
    public let title: String
    public var subtitle: String?          // 롤업 한 줄 요약 (예: "잘 먹고·잘 자고 있어요 👍")
    public var disclaimer: String?        // 하단 면책 캡션(있으면 표시)
    public let content: Content

    public init(
        title: String,
        subtitle: String? = nil,
        disclaimer: String? = DSDisclaimerCaption.standard,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.disclaimer = disclaimer
        self.content = content()
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: theme.space.stackGapMd) {
                // 헤더
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text(title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.color.textPrimary.color)
                    if let subtitle {
                        Text(subtitle)
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }
                }

                // 콘텐츠 슬롯
                content

                // 면책 캡션
                if let disclaimer {
                    Divider()
                        .overlay(theme.color.divider.color)
                    DSDisclaimerCaption(disclaimer)
                }
            }
        }
    }
}

#Preview("AnalysisCard — Light") {
    ScrollView {
        AnalysisCard(
            title: "오늘의 분석",
            subtitle: "잘 먹고·잘 자고 있어요 👍",
            disclaimer: "참고용이며 진단이 아니에요 · 출처 AAP·WHO"
        ) {
            VStack(spacing: 0) {
                InsightRow(icon: "drop.fill", label: "수유", value: "720ml",
                           statusTone: .success, statusText: "적정",
                           comment: "권장 600~720ml 안이에요 👍")
                Divider()
                InsightRow(icon: "moon.fill", label: "수면", value: "12.5시간",
                           statusTone: .warning, statusText: "권장보다 적음",
                           comment: "권장(14~17시간)보다 짧아요. 조금 더 재워볼까요?")
            }
        }
        .padding()
    }
    .environment(\.theme, .zzippu)
}

#Preview("AnalysisCard — Dark") {
    AnalysisCard(title: "오늘의 분석", subtitle: "대체로 권장 범위 안이에요 😊") {
        InsightRow(icon: "drop.fill", label: "수유", value: "720ml",
                   statusTone: .success, statusText: "적정",
                   comment: "권장 600~720ml 안이에요 👍")
    }
    .padding()
    .background(Color.black)
    .environment(\.theme, .zzippu)
    .preferredColorScheme(.dark)
}
