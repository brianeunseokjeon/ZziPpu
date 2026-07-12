// Domain/UseCases/Calendar/BuildMonthCalendarUseCase.swift
// 월 달력 그리드 + 데코레이션 + 배너 조립 오케스트레이터.
// providers 배열 DI — 미래 2종은 이 배열에 추가만 하면 View/집계 무변경.

import Foundation

struct BuildMonthCalendarUseCase {

    let providers: [CalendarDecorationProvider]   // 주입 (순서 무관)

    private let checkupSchedule = ComputeCheckupScheduleUseCase()

    /// 월 달력 완성 모델 반환.
    /// - Parameters:
    ///   - month: 해당 월의 임의 날짜 (내부에서 첫날로 정규화)
    ///   - baby:  활성 아기
    /// - Returns: 42칸 CalendarDay + 배너 정보
    func callAsFunction(month: Date, baby: Baby) async -> MonthCalendarModel {
        let cal    = Calendar.kst
        let today  = cal.startOfDay(for: Date.now)
        let days42 = make42Days(for: month)

        // 현재 달의 날짜만 표시 대상 (넘침칸 제외한 당월 날짜)
        let currentMonthDays = days42.filter { isInSameMonth(date: $0, asMonth: month) }

        // providers 병렬 호출
        var allDecos: [CalendarDayDecoration] = []
        await withTaskGroup(of: [CalendarDayDecoration].self) { group in
            for provider in providers {
                group.addTask {
                    // 넘침칸에는 데코 없음(당월 날짜만 넘김)
                    (try? await provider.decorations(forMonthDays: currentMonthDays, baby: baby)) ?? []
                }
            }
            for await decos in group {
                allDecos += decos
            }
        }

        // 날짜별 데코 묶음
        var decoByDay: [Date: [CalendarDayDecoration]] = [:]
        for d in allDecos {
            let key = cal.startOfDay(for: d.date)
            decoByDay[key, default: []].append(d)
        }

        // CalendarDay 42개 생성
        let calendarDays = days42.map { date -> CalendarDay in
            let dayStart    = cal.startOfDay(for: date)
            let outside     = !isInSameMonth(date: date, asMonth: month)
            let isFuture    = dayStart > today
            let isToday     = dayStart == today
            let decorations = outside ? [] : (decoByDay[dayStart] ?? [])

            return CalendarDay(
                id:             date,
                date:           date,
                isOutsideMonth: outside,
                isFuture:       isFuture,
                isToday:        isToday,
                decorations:    decorations
            )
        }

        // 배너: 오늘 기준 다가오는 검진
        let bannerInfo = checkupSchedule.nextWindow(birthDate: baby.birthDate, today: Date.now)

        return MonthCalendarModel(
            month:      cal.date(from: cal.dateComponents([.year, .month], from: month))!,
            days:       calendarDays,
            bannerInfo: bannerInfo
        )
    }

    // MARK: - Private

    /// 주어진 달에 대한 6주×7 = 42칸 날짜 배열(일요일 시작, KST 자정).
    private func make42Days(for month: Date) -> [Date] {
        var cal = Calendar.kst
        cal.firstWeekday = 1   // 일요일 = 1 (시스템 로캘 무시)

        // 이 달 첫날
        let comps    = cal.dateComponents([.year, .month], from: month)
        let firstDay = cal.date(from: comps)!

        // 첫날의 요일(일=1...토=7) → 그리드 시작점
        let weekday  = cal.component(.weekday, from: firstDay)
        let offset   = weekday - 1   // 일요일이면 0, 월요일이면 1 …

        // 그리드 시작 날짜
        let gridStart = cal.date(byAdding: .day, value: -offset, to: firstDay)!

        return (0..<42).compactMap {
            cal.date(byAdding: .day, value: $0, to: gridStart)
        }
    }

    private func isInSameMonth(date: Date, asMonth month: Date) -> Bool {
        let cal = Calendar.kst
        return cal.component(.year, from: date)  == cal.component(.year, from: month) &&
               cal.component(.month, from: date) == cal.component(.month, from: month)
    }
}
