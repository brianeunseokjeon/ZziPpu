// Feature/Dashboard/DashboardViewModel.swift
// 대시보드 ViewModel — 5종 Repository 병렬 로드 + 추세 집계.
// Domain 프로토콜만 의존(클린아키텍처).

import Foundation
import Observation

@Observable
final class DashboardViewModel {

    // MARK: - State

    var selectedDate: Date = .now
    var isLoading: Bool = false
    var errorMessage: String?

    // 서버 집계 (오늘 일별 요약)
    var dailySummary:  DailySummary       = .empty
    var prediction:    FeedingPrediction  = .empty

    // 7일 스파크라인 원본 데이터 (카드 미니 그래프용)
    var sparkFeedings: [Feeding]     = []
    var sparkSleeps:   [SleepRecord] = []
    var sparkDiapers:  [DiaperRecord] = []
    var sparkPlays:    [PlayRecord]  = []

    // 성장 시계열
    var growthSeries: [GrowthRecord] = []
    var latestGrowth: GrowthRecord?  { growthSeries.last }

    // MARK: - Dependencies

    private let dashboardRepository: DashboardRepository
    private let feedingRepository:   FeedingRepository
    private let sleepRepository:     SleepRepository
    private let diaperRepository:    DiaperRepository
    private let playRepository:      PlayRepository
    private let growthRepository:    GrowthRepository
    private let babyId: UUID

    // MARK: - UseCases (순수 집계)

    private let trendUseCase = ComputeTrendUseCase()

    // MARK: - Init

    init(
        dashboardRepository: DashboardRepository,
        feedingRepository:   FeedingRepository,
        sleepRepository:     SleepRepository,
        diaperRepository:    DiaperRepository,
        playRepository:      PlayRepository,
        growthRepository:    GrowthRepository,
        babyId: UUID
    ) {
        self.dashboardRepository = dashboardRepository
        self.feedingRepository   = feedingRepository
        self.sleepRepository     = sleepRepository
        self.diaperRepository    = diaperRepository
        self.playRepository      = playRepository
        self.growthRepository    = growthRepository
        self.babyId              = babyId
    }

    // MARK: - Actions

    func loadAll(for date: Date? = nil) {
        let target = date ?? selectedDate
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                // 병렬 로드
                async let summary    = dashboardRepository.dailySummary(babyId: babyId, date: target)
                async let pred       = dashboardRepository.predictions(babyId: babyId)
                async let growth     = growthRepository.series(babyId: babyId)

                // 7일 스파크라인용 각 날짜별 로드 (병렬)
                let sparkDates = last7Days(anchor: target)
                async let fAll = loadSparkFeedings(dates: sparkDates)
                async let sAll = loadSparkSleeps(dates: sparkDates)
                async let dAll = loadSparkDiapers(dates: sparkDates)
                async let pAll = loadSparkPlays(dates: sparkDates)

                dailySummary  = try await summary
                prediction    = try await pred
                growthSeries  = try await growth
                sparkFeedings = try await fAll
                sparkSleeps   = try await sAll
                sparkDiapers  = try await dAll
                sparkPlays    = try await pAll

            } catch {
                errorMessage = "대시보드 로드 실패: \(error.localizedDescription)"
            }
        }
    }

    func changeDate(_ date: Date) {
        selectedDate = date
        loadAll(for: date)
    }

    // MARK: - Computed: 7일 스파크라인 포인트 (미니 그래프)

    var feedingSparkPoints: [MetricPoint] {
        trendUseCase.feedingTrend(feedings: sparkFeedings, range: .week, anchorDate: selectedDate)
    }

    var sleepSparkPoints: [MetricPoint] {
        trendUseCase.sleepTrend(sleeps: sparkSleeps, range: .week, anchorDate: selectedDate)
    }

    var diaperSparkPoints: [MetricPoint] {
        trendUseCase.diaperTrend(diapers: sparkDiapers, range: .week, anchorDate: selectedDate)
    }

    var playSparkPoints: [MetricPoint] {
        trendUseCase.playTrend(plays: sparkPlays, range: .week, anchorDate: selectedDate)
    }

    // MARK: - Computed: 표시용 포맷

    var feedingSummaryText: String {
        let ml = dailySummary.totalFeedingMl
        let cnt = dailySummary.feedingCount
        return ml > 0 ? "\(ml)ml" : (cnt > 0 ? "\(cnt)회" : "기록 없음")
    }

    var feedingSubText: String {
        "\(dailySummary.feedingCount)회"
    }

    var sleepSummaryText: String {
        let min = dailySummary.totalSleepMinutes
        guard min > 0 else { return "기록 없음" }
        let h = min / 60; let m = min % 60
        return h > 0 ? "\(h)시간 \(m > 0 ? "\(m)분" : "")" : "\(m)분"
    }

    var diaperSummaryText: String {
        let total = dailySummary.diaperCount
        return total > 0 ? "\(total)회" : "기록 없음"
    }

    var diaperSubText: String {
        "소\(dailySummary.peeCount) 대\(dailySummary.poopCount)"
    }

    var playSummaryText: String {
        let min = dailySummary.totalPlayMinutes
        guard min > 0 else { return "기록 없음" }
        return "\(min)분"
    }

    var playSubText: String {
        let tt = dailySummary.tummyTimeMinutes
        return tt > 0 ? "터미타임 \(tt)분" : ""
    }

    var latestWeightText: String {
        guard let w = latestGrowth?.weightG else { return "—" }
        return String(format: "%.1fkg", Double(w) / 1000.0)
    }

    var latestHeightText: String {
        guard let h = latestGrowth?.heightCm else { return "—" }
        return String(format: "%.1fcm", h)
    }

    var nextFeedingText: String {
        guard let next = prediction.nextFeedingAt else { return "예측 없음" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: next)
    }

    // MARK: - Private Helpers

    private func last7Days(anchor: Date) -> [Date] {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: anchor) }.reversed()
    }

    private func loadSparkFeedings(dates: [Date]) async throws -> [Feeding] {
        var all: [Feeding] = []
        for date in dates {
            let items = try await feedingRepository.list(babyId: babyId, on: date)
            all += items
        }
        return all
    }

    private func loadSparkSleeps(dates: [Date]) async throws -> [SleepRecord] {
        var all: [SleepRecord] = []
        for date in dates {
            let items = try await sleepRepository.list(babyId: babyId, on: date)
            all += items
        }
        return all
    }

    private func loadSparkDiapers(dates: [Date]) async throws -> [DiaperRecord] {
        var all: [DiaperRecord] = []
        for date in dates {
            let items = try await diaperRepository.list(babyId: babyId, on: date)
            all += items
        }
        return all
    }

    private func loadSparkPlays(dates: [Date]) async throws -> [PlayRecord] {
        var all: [PlayRecord] = []
        for date in dates {
            let items = try await playRepository.list(babyId: babyId, on: date)
            all += items
        }
        return all
    }
}
