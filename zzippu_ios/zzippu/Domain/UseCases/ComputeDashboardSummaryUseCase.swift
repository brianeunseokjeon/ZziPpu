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
        // 수유 타입별 분리(도넛 세그먼트용). 모유는 ml 미기록이 흔하므로 회수도 함께 노출.
        let formulaMl:         Int
        let breastMl:          Int   // 모유 중 ml 기록이 있는 분량(있을 때만)
        let formulaCount:      Int
        let breastCount:       Int
        let totalSleepMinutes: Int
        let sleepCount:        Int
        let diaperCount:       Int
        let poopCount:         Int
        let peeCount:          Int
        let totalPlayMinutes:  Int
        let tummyTimeMinutes:  Int
    }

    // MARK: - Feeding breakdown (도넛 전용 순수 집계)

    /// 수유 타입별 비중 집계. UI(도넛)는 이 값만 받음.
    struct FeedingBreakdown: Equatable, Sendable {
        let formulaMl:    Int
        let breastMl:     Int
        let formulaCount: Int
        let breastCount:  Int

        static let empty = FeedingBreakdown(formulaMl: 0, breastMl: 0, formulaCount: 0, breastCount: 0)
    }

    func feedingBreakdown(_ feedings: [Feeding]) -> FeedingBreakdown {
        let formula = feedings.filter { $0.type == .formula }
        let breast  = feedings.filter { $0.type.isBreast }
        return FeedingBreakdown(
            formulaMl:    formula.compactMap(\.amountMl).reduce(0, +),
            breastMl:     breast.compactMap(\.amountMl).reduce(0, +),
            formulaCount: formula.count,
            breastCount:  breast.count
        )
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

        let breakdown = feedingBreakdown(input.feedings)

        return Output(
            totalFeedingMl:    totalFeedingMl,
            feedingCount:      input.feedings.count,
            formulaMl:         breakdown.formulaMl,
            breastMl:          breakdown.breastMl,
            formulaCount:      breakdown.formulaCount,
            breastCount:       breakdown.breastCount,
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
