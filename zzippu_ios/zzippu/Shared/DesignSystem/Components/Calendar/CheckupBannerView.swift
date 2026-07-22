// Shared/DesignSystem/Components/Calendar/CheckupBannerView.swift
// 다가오는 영유아 검진 D-day 배너.

import SwiftUI

struct CheckupBannerView: View {

    let bannerInfo: CheckupBannerInfo

    @Environment(\.theme) private var theme

    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.timeZone = .kst
        f.setLocalizedDateFormatFromTemplate("Md")   // 기기 언어
        return f
    }()

    var body: some View {
        switch bannerInfo {
        case .upcoming(let order, let dDay, let start, let end):
            bannerContent(
                round: order,
                badge: "\(order)차",
                dDayText: "D-\(dDay)",
                rangeText: "\(dateFmt.string(from: start))~\(dateFmt.string(from: end))",
                isInProgress: false
            )

        case .inProgress(let order, let daysLeft, let start, let end):
            bannerContent(
                round: order,
                badge: "\(order)차",
                dDayText: "진행 중",
                rangeText: "마감까지 \(daysLeft)일 (\(dateFmt.string(from: start))~\(dateFmt.string(from: end)))",
                isInProgress: true
            )

        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private func bannerContent(round: Int, badge: String, dDayText: String, rangeText: String, isInProgress: Bool) -> some View {
        let checkupColor = theme.color.checkupColor(round: round).color  // 차수별 색
        HStack(alignment: .center, spacing: theme.space.stackGapSm) {
            // 좌측 도트 (색맹 대비 아이콘 병행)
            Image(systemName: "stethoscope")
                .font(.system(size: 14))
                .foregroundStyle(checkupColor)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("다가오는 검진: ")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.color.textPrimary.color)

                    Text("\(badge) · \(dDayText)")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(checkupColor)
                }

                Text(rangeText)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
            }

            Spacer()
        }
        .padding(.horizontal, theme.space.componentPaddingX)
        .padding(.vertical, theme.space.stackGapSm)
        .background(theme.color.surfaceSunken.color)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bannerAccessibilityLabel(badge: badge, dDayText: dDayText, rangeText: rangeText))
    }

    private func bannerAccessibilityLabel(badge: String, dDayText: String, rangeText: String) -> String {
        "다가오는 검진. \(badge). \(dDayText). 기간 \(rangeText)."
    }
}

#Preview("CheckupBanner — upcoming") {
    let start = Calendar.kst.date(byAdding: .day, value: 40, to: Date.now)!
    let end   = Calendar.kst.date(byAdding: .day, value: 130, to: Date.now)!
    return CheckupBannerView(bannerInfo: .upcoming(order: 2, dDay: 40, start: start, end: end))
        .padding()
        .environment(\.theme, .zzippu)
}

#Preview("CheckupBanner — in progress") {
    let start = Calendar.kst.date(byAdding: .day, value: -10, to: Date.now)!
    let end   = Calendar.kst.date(byAdding: .day, value: 80,  to: Date.now)!
    return CheckupBannerView(bannerInfo: .inProgress(order: 2, daysLeft: 80, start: start, end: end))
        .padding()
        .environment(\.theme, .zzippu)
}

#Preview("CheckupBanner — dark") {
    let start = Calendar.kst.date(byAdding: .day, value: 40, to: Date.now)!
    let end   = Calendar.kst.date(byAdding: .day, value: 130, to: Date.now)!
    return CheckupBannerView(bannerInfo: .upcoming(order: 3, dDay: 40, start: start, end: end))
        .padding()
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
