// Shared/Extensions/Date+.swift

import Foundation

extension Date {
    /// 해당 날짜의 자정(시작)~다음 날 자정(끝) 튜플
    var dayBounds: (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: self)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }

    /// "오늘", "어제", "MM월 dd일" 등 상대적 표기
    var relativeLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(self)     { return "오늘" }
        if cal.isDateInYesterday(self) { return "어제" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일"
        return fmt.string(from: self)
    }

    /// HH:mm 형식
    var timeString: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: self)
    }
}
