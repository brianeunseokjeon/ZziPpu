// Domain/UseCases/Calendar/StaticVolumeDecorationProvider.swift
// CalendarDecorationProvider 구현 — 미리 확보한 수유 총량(캐시 스냅샷)을 그대로 데코로.
// FeedingVolumeDecorationProvider 와 동일 출력이되 네트워크/DB 호출 없음(SWR hydrate 용).

import Foundation

struct StaticVolumeDecorationProvider: CalendarDecorationProvider {

    var kind: CalendarDecorationKind { .feedingVolume }

    /// KST 자정 날짜 → 총 ml.
    private let byDay: [Date: Int]

    init(volumes: [DateVolume]) {
        let cal = Calendar.kst
        var map: [Date: Int] = [:]
        for dv in volumes {
            map[cal.startOfDay(for: dv.day)] = dv.totalMl
        }
        self.byDay = map
    }

    func decorations(forMonthDays days: [Date], baby: Baby) async throws -> [CalendarDayDecoration] {
        let cal = Calendar.kst
        var result: [CalendarDayDecoration] = []
        for day in days {
            let dayStart = cal.startOfDay(for: day)
            guard let ml = byDay[dayStart], ml > 0 else { continue }
            result.append(CalendarDayDecoration(
                date: day,
                kind: .feedingVolume,
                slot: .primaryValue,
                text: "\(ml)"           // FeedingVolumeDecorationProvider 와 동일 포맷
            ))
        }
        return result
    }
}
