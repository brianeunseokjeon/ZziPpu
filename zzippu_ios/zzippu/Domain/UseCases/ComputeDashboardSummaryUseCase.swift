// Domain/UseCases/ComputeDashboardSummaryUseCase.swift
// 순수 집계 로직 — 클라 보유 기록에서 DailySummary 동등 값 계산.
// 서버 응답 없을 때 폴백 or 클라 집계 대조용.
// Foundation only — SwiftUI/SwiftData import 금지.

import Foundation

struct ComputeDashboardSummaryUseCase {

    // MARK: - Input

    struct Input {
        let feedings: [Feeding]
        let sleeps:   [SleepRecord]
        let diapers:  [DiaperRecord]
        let plays:    [PlayRecord]
    }

    // MARK: - Output

    struct Output {
        let totalFeedingMl:    Int
        let feedingCount:      Int
        let totalSleepMinutes: Int
        let sleepCount:        Int
        let diaperCount:       Int
        let poopCount:         Int
        let peeCount:          Int
        let totalPlayMinutes:  Int
        let tummyTimeMinutes:  Int
    }

    // MARK: - Execute

    func execute(_ input: Input) -> Output {
        let totalFeedingMl = input.feedings
            .compactMap(\.amountMl)
            .reduce(0, +)

        let totalSleepMinutes = input.sleeps
            .compactMap(\.durationMinutes)
            .reduce(0, +)

        let poopCount = input.diapers.filter { $0.diaperType == .poo || $0.diaperType == .both }.count
        let peeCount  = input.diapers.filter { $0.diaperType == .pee || $0.diaperType == .both }.count

        let totalPlayMinutes = input.plays
            .compactMap(\.durationMinutes)
            .reduce(0, +)

        let tummyTimeMinutes = input.plays
            .filter { $0.playType == .tummyTime }
            .compactMap(\.durationMinutes)
            .reduce(0, +)

        return Output(
            totalFeedingMl:    totalFeedingMl,
            feedingCount:      input.feedings.count,
            totalSleepMinutes: totalSleepMinutes,
            sleepCount:        input.sleeps.count,
            diaperCount:       input.diapers.count,
            poopCount:         poopCount,
            peeCount:          peeCount,
            totalPlayMinutes:  totalPlayMinutes,
            tummyTimeMinutes:  tummyTimeMinutes
        )
    }
}
