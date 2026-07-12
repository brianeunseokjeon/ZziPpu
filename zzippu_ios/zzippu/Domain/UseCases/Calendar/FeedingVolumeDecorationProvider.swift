// Domain/UseCases/Calendar/FeedingVolumeDecorationProvider.swift
// CalendarDecorationProvider 구현 — 월 수유량 집계 → 날짜별 primaryValue 텍스트.
// FeedingRepository.dailyTotals(로컬 우선) 를 호출해 42칸 일괄 집계.

import Foundation

struct FeedingVolumeDecorationProvider: CalendarDecorationProvider {

    var kind: CalendarDecorationKind { .feedingVolume }

    private let feedingRepository: FeedingRepository

    init(feedingRepository: FeedingRepository) {
        self.feedingRepository = feedingRepository
    }

    func decorations(forMonthDays days: [Date], baby: Baby) async throws -> [CalendarDayDecoration] {
        guard !days.isEmpty else { return [] }

        let cal = Calendar.kst
        // 42칸 범위: 첫날~끝날 (넘침칸 포함)
        let start = cal.startOfDay(for: days.first!)
        let end   = cal.startOfDay(for: days.last!)

        let totals = try await feedingRepository.dailyTotals(
            babyId: baby.id,
            from: start,
            to: end
        )

        // [KST 자정 날짜: ml] 딕셔너리로 변환
        var byDay: [Date: Int] = [:]
        for dv in totals {
            byDay[cal.startOfDay(for: dv.day)] = dv.totalMl
        }

        var result: [CalendarDayDecoration] = []
        for day in days {
            let dayStart = cal.startOfDay(for: day)
            guard let ml = byDay[dayStart], ml > 0 else { continue }
            result.append(CalendarDayDecoration(
                date: day,
                kind: .feedingVolume,
                slot: .primaryValue,
                text: "\(ml)"           // 숫자만 ("720"), 단위는 범례에
            ))
        }
        return result
    }
}
