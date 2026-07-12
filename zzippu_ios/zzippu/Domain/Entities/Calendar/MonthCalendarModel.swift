// Domain/Entities/Calendar/MonthCalendarModel.swift
// BuildMonthCalendarUseCase 가 View 에 넘기는 완성 모델.
// Foundation only.

import Foundation

// MARK: - CalendarDay

/// 달력 그리드 한 칸의 모든 정보.
struct CalendarDay: Identifiable {
    let id: Date                                    // KST 자정 (고유 키)
    let date: Date                                  // 동일 (id 별칭)
    let isOutsideMonth: Bool                        // 넘침칸(이전/다음달)
    let isFuture: Bool                              // 오늘 이후
    let isToday: Bool
    let decorations: [CalendarDayDecoration]

    /// 접근성 라벨 합성 (VoiceOver용).
    func accessibilityLabel(monthFormatter: DateFormatter) -> String {
        guard !isOutsideMonth else { return "\(dateLabel). 이번 달 아님." }

        var parts: [String] = [dateLabel]
        if isToday { parts.append("오늘") }

        if let vol = volumeText {
            parts.append("총 수유 \(vol)밀리리터")
        } else if !isFuture {
            parts.append("수유 기록 없음")
        }

        for deco in decorations where deco.slot == .eventBadge {
            if let t = deco.text { parts.append("\(t) 검진 시작일") }
        }
        let isInCheckup = decorations.contains { $0.slot == .underbar && $0.kind == .checkupWindow }
        if isInCheckup && decorations.first(where: { $0.slot == .eventBadge }) == nil {
            if let t = decorations.first(where: { $0.slot == .underbar })?.text {
                parts.append("\(t) 검진 기간")
            }
        }

        return parts.joined(separator: ". ")
    }

    /// 수유량 데코 텍스트 (primaryValue 슬롯).
    var volumeText: String? {
        decorations.first(where: { $0.slot == .primaryValue })?.text
    }

    /// 이벤트 배지 데코 (eventBadge 슬롯, 최대 1개 → 오버플로우는 "+N").
    var eventBadgeDecorations: [CalendarDayDecoration] {
        decorations.filter { $0.slot == .eventBadge }
    }

    /// 언더바 데코 (underbar 슬롯, 최대 2겹).
    var underbarDecorations: [CalendarDayDecoration] {
        Array(decorations.filter { $0.slot == .underbar }.prefix(2))
    }

    // MARK: - Private

    private var dateLabel: String {
        let cal = Calendar.kst
        let month = cal.component(.month, from: date)
        let day   = cal.component(.day,   from: date)
        return "\(month)월 \(day)일"
    }
}

// MARK: - CheckupBannerInfo

/// 달력 하단 검진 배너 정보.
enum CheckupBannerInfo {
    case upcoming(order: Int, dDay: Int, start: Date, end: Date)   // D-day(미래)
    case inProgress(order: Int, daysLeft: Int, start: Date, end: Date)  // 진행 중
    case none                                                        // 예정 없음(8차 종료 후)
}

// MARK: - MonthCalendarModel

/// BuildMonthCalendarUseCase 완성 출력.
struct MonthCalendarModel {
    let month: Date                         // 해당 월의 첫날(KST 자정)
    let days: [CalendarDay]                 // 42칸 고정(6주×7)
    let bannerInfo: CheckupBannerInfo

    /// 그리드를 7칸씩 묶어 주(週) 배열로.
    var weeks: [[CalendarDay]] {
        stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }

    static var empty: MonthCalendarModel {
        MonthCalendarModel(month: Date.now, days: [], bannerInfo: .none)
    }
}
