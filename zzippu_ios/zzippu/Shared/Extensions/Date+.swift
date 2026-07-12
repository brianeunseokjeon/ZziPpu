// Shared/Extensions/Date+.swift
//
// 날짜 표시·경계·상대라벨 헬퍼. 시간대 민감 로직은 모두 KST(Asia/Seoul) 고정.
// (저장/전송은 UTC 유지 — 여기서는 표시·그룹핑·오늘판별만 KST로 계산.)

import Foundation

extension Date {
    /// 해당 날짜의 KST 자정(시작)~다음 날 KST 자정(끝) 튜플
    var dayBounds: (start: Date, end: Date) {
        let cal = Calendar.kst
        let start = cal.startOfDay(for: self)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }

    /// "오늘", "어제", "MM월 dd일" 등 상대적 표기 (KST 기준)
    var relativeLabel: String {
        let cal = Calendar.kst
        if cal.isDateInToday(self)     { return "오늘" }
        if cal.isDateInYesterday(self) { return "어제" }
        return Date.krMonthDayFormatter.string(from: self)
    }

    /// HH:mm 형식 (KST 기준)
    var timeString: String {
        Date.krTimeFormatter.string(from: self)
    }

    // MARK: - 공용 KST 포맷터 (재사용)

    /// "M월 d일" (KST)
    static let krMonthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = .kst
        f.dateFormat = "M월 d일"
        return f
    }()

    /// "오전/오후 h:mm" (KST) — 웹 formatTime(Intl ko-KR, hour12) 정합. 예: "오후 2:30".
    static let krTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = .kst
        f.dateFormat = "a h:mm"
        return f
    }()
}
