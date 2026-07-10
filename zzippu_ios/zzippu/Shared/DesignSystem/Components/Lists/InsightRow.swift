// Shared/DesignSystem/Components/Lists/InsightRow.swift
// 지표별 인사이트 한 줄 행 — [아이콘 + 라벨(+값)] + DSStatusPill + 한 줄 코멘트.
// DS-순수: Domain 타입 비의존. 피처가 DomainInsight → 파라미터로 변환해 사용.
// theme 토큰만 사용. Open-Closed: icon/value/pill 선택적.

import SwiftUI

public struct InsightRow: View {
    public let icon: String            // SF Symbol
    public let label: String
    public var value: String?          // 예: "720ml"
    public let statusTone: StatusTone
    public let statusText: String      // pill 라벨
    public let comment: String

    public init(
        icon: String,
        label: String,
        value: String? = nil,
        statusTone: StatusTone,
        statusText: String,
        comment: String
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.statusTone = statusTone
        self.statusText = statusText
        self.comment = comment
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        HStack(alignment: .top, spacing: theme.space.stackGapMd) {
            // 아이콘 (톤 색)
            Image(systemName: icon)
                .font(theme.typography.headline)
                .foregroundStyle(theme.color.status(tone: statusTone).solid.color)
                .frame(width: theme.space.lg, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: theme.space.xs) {
                // 상단: 라벨(+값) ---- pill
                HStack(spacing: theme.space.sm) {
                    Text(label)
                        .font(theme.typography.bodyStrong)
                        .foregroundStyle(theme.color.textPrimary.color)

                    if let value {
                        Text(value)
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }

                    Spacer(minLength: theme.space.sm)

                    DSStatusPill(tone: statusTone, text: statusText)
                }

                // 하단: 코멘트
                Text(comment)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, theme.space.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value ?? "") \(statusText). \(comment)")
    }
}

#Preview("InsightRow — Light") {
    VStack(spacing: 0) {
        InsightRow(icon: "drop.fill", label: "수유", value: "720ml",
                   statusTone: .success, statusText: "적정",
                   comment: "오늘 수유 720ml — 권장 600~720ml 안이에요 👍")
        Divider()
        InsightRow(icon: "moon.fill", label: "수면", value: "12.5시간",
                   statusTone: .warning, statusText: "권장보다 적음",
                   comment: "권장(14~17시간)보다 짧아요. 조금 더 재워볼까요?")
        Divider()
        InsightRow(icon: "chart.bar.fill", label: "대변", value: "0회",
                   statusTone: .info, statusText: "정보 없음",
                   comment: "기록이 더 쌓이면 분석해 드릴게요 📊")
    }
    .padding()
    .environment(\.theme, .zzippu)
}

#Preview("InsightRow — Dark") {
    VStack(spacing: 0) {
        InsightRow(icon: "drop.fill", label: "수유", value: "980ml",
                   statusTone: .info, statusText: "권장보다 많음",
                   comment: "권장보다 많아요. 보통은 괜찮지만 이상이 있으면 소아과 상담을 권장드려요")
    }
    .padding()
    .background(Color.black)
    .environment(\.theme, .zzippu)
    .preferredColorScheme(.dark)
}
