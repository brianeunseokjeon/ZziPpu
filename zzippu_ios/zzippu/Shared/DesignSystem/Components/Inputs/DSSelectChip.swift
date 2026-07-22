// Shared/DesignSystem/Components/Inputs/DSSelectChip.swift
// 선택 칩(라디우스 8·가로패딩 12) + 왼쪽정렬 자동 줄바꿈 FlowLayout.
// "종류/프리셋" 류 UI의 공용 스타일 — 이후 동일 UI는 이 컴포넌트를 사용.

import SwiftUI

// MARK: - DSSelectChip

/// 선택 가능한 칩. 선택=info 채움+흰 글자 / 미선택=surfaceSunken.
/// 표준 스타일: cornerRadius 8, 가로 패딩 12, 세로 패딩 8.
struct DSSelectChip: View {
    let label: String
    var isSelected: Bool = false
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(theme.typography.captionStrong)
                .foregroundStyle(isSelected ? theme.color.onPrimary.color : theme.color.textSecondary.color)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? theme.color.statusInfoSolid.color : theme.color.surfaceSunken.color)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout

/// 왼쪽 정렬 자동 줄바꿈 레이아웃(칩 나열용). 내용 폭에 맞춰 좌→우로 채우고 넘치면 다음 줄.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
