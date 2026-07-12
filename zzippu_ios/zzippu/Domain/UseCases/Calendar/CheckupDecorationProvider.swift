// Domain/UseCases/Calendar/CheckupDecorationProvider.swift
// CalendarDecorationProvider 구현 — 검진 창 → eventBadge(시작일) + underbar(구간).
// 순수 계산(네트워크 0). 생일만 있으면 된다.

import Foundation

struct CheckupDecorationProvider: CalendarDecorationProvider {

    var kind: CalendarDecorationKind { .checkupWindow }

    private let scheduleUseCase = ComputeCheckupScheduleUseCase()

    func decorations(forMonthDays days: [Date], baby: Baby) async throws -> [CalendarDayDecoration] {
        let cal = Calendar.kst
        let windows = scheduleUseCase(birthDate: baby.birthDate)

        var result: [CalendarDayDecoration] = []

        for window in windows {
            let wStart = cal.startOfDay(for: window.start)
            let wEnd   = cal.startOfDay(for: window.end)

            // 이 달 날짜 중 창 구간에 속하는 날 필터
            let windowDays = days.filter { d in
                let day = cal.startOfDay(for: d)
                return day >= wStart && day <= wEnd
            }

            guard !windowDays.isEmpty else { continue }

            // (b) 시작일 eventBadge: 이 달 날짜 중 wStart와 일치하는 날만
            if let startDay = days.first(where: { cal.startOfDay(for: $0) == wStart }) {
                result.append(CalendarDayDecoration(
                    date: startDay,
                    kind: .checkupWindow,
                    slot: .eventBadge,
                    text: window.orderLabel,  // "2차"
                    colorIndex: window.order  // 차수별 색
                ))
            }

            // (a-lite) 창 구간 underbar
            for day in windowDays {
                let dayStart = cal.startOfDay(for: day)
                let spanRole: SpanRole

                let isFirst  = dayStart == wStart
                let isLast   = dayStart == wEnd
                let isOnlyOne = isFirst && isLast

                if isOnlyOne { spanRole = .single }
                else if isFirst { spanRole = .start }
                else if isLast  { spanRole = .end }
                else            { spanRole = .middle }

                result.append(CalendarDayDecoration(
                    date: day,
                    kind: .checkupWindow,
                    slot: .underbar,
                    text: window.orderLabel,
                    spanRole: spanRole,
                    colorIndex: window.order  // 차수별 색
                ))
            }
        }

        return result
    }
}
