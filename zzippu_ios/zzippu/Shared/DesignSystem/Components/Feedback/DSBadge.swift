// Shared/DesignSystem/Components/Feedback/DSBadge.swift
// 도메인 태그 배지. bg=domain.tint, fg=domain.solid.
// 새 도메인 추가: DomainKind에 케이스 추가 + tokens.json 확장만으로 자동 반영.

import SwiftUI

public struct DSBadge: View {
    public let domain: DomainKind
    public let text:   String

    public init(domain: DomainKind, text: String) {
        self.domain = domain
        self.text   = text
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        Text(text)
            .font(theme.typography.label)
            .foregroundStyle(theme.color.solid(for: domain).color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(theme.color.tint(for: domain).color)
            .clipShape(Capsule())
    }
}

#Preview("DSBadge") {
    VStack(spacing: 8) {
        HStack {
            DSBadge(domain: .feedingFormula,     text: "분유")
            DSBadge(domain: .feedingBreastLeft,  text: "모유 좌")
            DSBadge(domain: .feedingBreastRight, text: "모유 우")
            DSBadge(domain: .feedingBreastBoth,  text: "양쪽")
        }
        HStack {
            DSBadge(domain: .diaperPee,   text: "소변")
            DSBadge(domain: .diaperPoop,  text: "대변")
            DSBadge(domain: .diaperBoth,  text: "둘 다")
        }
        HStack {
            DSBadge(domain: .sleep, text: "수면")
            DSBadge(domain: .play,  text: "놀이")
        }
    }
    .padding()
    .environment(\.theme, .zzippu)
}
