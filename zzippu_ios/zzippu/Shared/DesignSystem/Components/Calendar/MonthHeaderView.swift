// Shared/DesignSystem/Components/Calendar/MonthHeaderView.swift
// 월 헤더 — ‹ 2026년 7월 › + "오늘" 버튼.

import SwiftUI

struct MonthHeaderView: View {

    let month: Date
    let canGoPrevious: Bool
    let canGoNext: Bool
    let isShowingToday: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    @Environment(\.theme) private var theme

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.timeZone = .kst
        fmt.dateFormat = "yyyy년 M월"
        return fmt.string(from: month)
    }

    var body: some View {
        HStack(spacing: 0) {
            // 이전달 chevron
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.color.textSecondary.color)
                    .opacity(canGoPrevious ? 1 : PrimitiveScale.opacityMuted)
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoPrevious)
            .accessibilityLabel("이전 달")

            Spacer()

            // 월 텍스트 (가운데)
            Text(monthTitle)
                .font(theme.typography.headline)
                .foregroundStyle(theme.color.textStrong.color)

            Spacer()

            // "오늘" 버튼 (이번 달 아닐 때만 노출, 레이아웃 점프 방지 위해 opacity로 숨김)
            Button(action: onToday) {
                Text("오늘")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.primary.color)
                    .padding(.horizontal, theme.component.statusPillPaddingX)
                    .padding(.vertical, theme.component.statusPillPaddingY)
                    .background(theme.color.primaryTint.color)
                    .clipShape(Capsule())
            }
            .opacity(isShowingToday ? 0 : 1)
            .disabled(isShowingToday)
            .accessibilityLabel("오늘로 이동")
            .accessibilityHidden(isShowingToday)

            // 다음달 chevron
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.color.textSecondary.color)
                    .opacity(canGoNext ? 1 : PrimitiveScale.opacityMuted)
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoNext)
            .accessibilityLabel("다음 달")
        }
        .frame(height: 44)
    }
}

#Preview("MonthHeader — not today") {
    return MonthHeaderView(
        month: Calendar.kst.date(byAdding: .month, value: -1, to: Date.now)!,
        canGoPrevious: true,
        canGoNext: true,
        isShowingToday: false,
        onPrevious: {},
        onNext: {},
        onToday: {}
    )
    .padding()
    .environment(\.theme, .zzippu)
}

#Preview("MonthHeader — today") {
    return MonthHeaderView(
        month: Date.now,
        canGoPrevious: true,
        canGoNext: false,
        isShowingToday: true,
        onPrevious: {},
        onNext: {},
        onToday: {}
    )
    .padding()
    .environment(\.theme, .zzippu)
}
