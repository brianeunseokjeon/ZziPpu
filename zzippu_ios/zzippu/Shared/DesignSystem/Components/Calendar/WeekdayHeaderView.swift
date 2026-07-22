// Shared/DesignSystem/Components/Calendar/WeekdayHeaderView.swift
// 요일 헤더 — 일~토, 주말 색 분기 (애플 캘린더 관례).

import SwiftUI

struct WeekdayHeaderView: View {

    // 기기 언어 요일 심볼(일요일 시작 — 배열 index 0=일). ko "일월화…" / en "SMTWTFS".
    private let weekdays: [String] = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = .current
        return cal.veryShortWeekdaySymbols
    }()

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.component.calendarCell.spacing) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { idx, label in
                Text(label)
                    .font(theme.typography.label)
                    .foregroundStyle(weekdayColor(for: idx))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekdayColor(for index: Int) -> Color {
        switch index {
        case 0: return theme.color.statusDangerFg.color   // 일요일 — rose
        case 6: return theme.color.statusInfoFg.color     // 토요일 — blue
        default: return theme.color.textSecondary.color
        }
    }
}

#Preview {
    WeekdayHeaderView()
        .padding()
        .environment(\.theme, .zzippu)
}
