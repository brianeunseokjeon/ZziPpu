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

    // 활성 아기 (나이·성별 파생)
    var activeBaby: Baby?

    // "오늘의 분석" 결과 (EvaluateInsightsUseCase 산출)
    var insights: [DomainInsight] = []
    var insightsHeadline: String = ""

    // MARK: - Dependencies

    private let dashboardRepository: DashboardRepository
    private let feedingRepository:   FeedingRepository
    private let sleepRepository:     SleepRepository
    private let diaperRepository:    DiaperRepository
    private let playRepository:      PlayRepository
    private let growthRepository:    GrowthRepository
    private let babyRepository:      BabyRepository
    private let guidelineRepository: GuidelineRepository
    private let babyId: UUID

    // MARK: - UseCases (순수 집계)

    private let trendUseCase = ComputeTrendUseCase()
    private let insightsUseCase: EvaluateInsightsUseCase

    // MARK: - Init

    init(
        dashboardRepository: DashboardRepository,
        feedingRepository:   FeedingRepository,
        sleepRepository:     SleepRepository,
        diaperRepository:    DiaperRepository,
        playRepository:      PlayRepository,
        growthRepository:    GrowthRepository,
        babyRepository:      BabyRepository,
        guidelineRepository: GuidelineRepository,
        babyId: UUID
    ) {
        self.dashboardRepository = dashboardRepository
        self.feedingRepository   = feedingRepository
        self.sleepRepository     = sleepRepository
        self.diaperRepository    = diaperRepository
        self.playRepository      = playRepository
        self.growthRepository    = growthRepository
        self.babyRepository      = babyRepository
        self.guidelineRepository = guidelineRepository
        self.babyId              = babyId
        self.insightsUseCase     = EvaluateInsightsUseCase(repository: guidelineRepository)
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
                async let baby       = babyRepository.fetch(id: babyId)

                // 7일 스파크라인용 각 날짜별 로드 (병렬)
                let sparkDates = last7Days(anchor: target)
                async let fAll = loadSparkFeedings(dates: sparkDates)
                async let sAll = loadSparkSleeps(dates: sparkDates)
                async let dAll = loadSparkDiapers(dates: sparkDates)
                async let pAll = loadSparkPlays(dates: sparkDates)

                dailySummary  = try await summary
                prediction    = try await pred
                growthSeries  = try await growth
                activeBaby    = try await baby
                sparkFeedings = try await fAll
                sparkSleeps   = try await sAll
                sparkDiapers  = try await dAll
                sparkPlays    = try await pAll

                recomputeInsights()

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
        fmt.timeZone = .kst
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: next)
    }

    /// 수유 적정량 게이지용 권장 범위(ml). 체중 기반(가이드 연동). 없으면 nil → 게이지 밴드 생략.
    var feedingRecommendedRange: ClosedRange<Double>? {
        insights.first { $0.kind == .feeding }?.recommendedRange
    }

    /// 수면 추세 차트용 권장 범위(분). 엔진은 시간(h) 단위 → 차트 y(분)에 맞게 ×60.
    var sleepRecommendedRangeMinutes: ClosedRange<Double>? {
        guard let h = insights.first(where: { $0.kind == .sleep })?.recommendedRange else { return nil }
        return (h.lowerBound * 60)...(h.upperBound * 60)
    }

    // MARK: - Insights (오늘의 분석)

    /// 집계값 + 활성아기 나이/체중으로 InsightInput 구성 → EvaluateInsightsUseCase 실행.
    /// 가이드 로드 실패(번들 누락 등)해도 앱은 깨지지 않게 빈 결과로 폴백.
    private func recomputeInsights() {
        let input = makeInsightInput()
        do {
            let result = try insightsUseCase.evaluate(input)
            insights = result
            insightsHeadline = insightsUseCase.rollupHeadline(result)
        } catch {
            insights = []
            insightsHeadline = "분석 데이터를 준비 중이에요 📊"
        }
    }

    private func makeInsightInput() -> InsightInput {
        // 나이(개월): 출생일 → 오늘. 아기 미로딩 시 0.
        let months: Int = {
            guard let birth = activeBaby?.birthDate else { return 0 }
            let comps = Calendar.kst.dateComponents([.month], from: birth, to: selectedDate)
            return max(0, comps.month ?? 0)
        }()

        // 체중(kg): 최신 성장기록 우선, 없으면 출생 체중.
        let weightKg: Double? = {
            if let g = latestGrowth?.weightG, g > 0 { return Double(g) / 1000.0 }
            if let bw = activeBaby?.birthWeightG, bw > 0 { return Double(bw) / 1000.0 }
            return nil
        }()

        // 오늘 집계값 (DailySummary — 서버 집계).
        let feedingMl = dailySummary.totalFeedingMl > 0 ? Double(dailySummary.totalFeedingMl) : nil
        let sleepH    = dailySummary.totalSleepMinutes > 0
            ? Double(dailySummary.totalSleepMinutes) / 60.0 : nil
        let peeC      = dailySummary.peeCount > 0 ? Double(dailySummary.peeCount) : nil
        let poopC     = dailySummary.poopCount > 0 ? Double(dailySummary.poopCount) : nil
        let tummyMin  = dailySummary.tummyTimeMinutes > 0
            ? Double(dailySummary.tummyTimeMinutes) : nil

        return InsightInput(
            ageMonths: months,
            weightKg: weightKg,
            isBreastfeeding: false,     // 수유 방식 개인화는 후순위 — 분유 기준
            validDays: validRecordDays,
            feedingMlPerDay: feedingMl,
            sleepHoursPerDay: sleepH,
            peeCountPerDay: peeC,
            poopCountPerDay: poopC,
            tummyTimeMinPerDay: tummyMin
        )
    }

    /// 최근 7일 중 기록이 하나라도 있는 날 수 (유효일수). <3이면 엔진이 noData 처리.
    private var validRecordDays: Int {
        let cal = Calendar.kst
        var days = Set<Date>()
        for f in sparkFeedings { days.insert(cal.startOfDay(for: f.startedAt)) }
        for s in sparkSleeps   { days.insert(cal.startOfDay(for: s.startedAt)) }
        for d in sparkDiapers  { days.insert(cal.startOfDay(for: d.recordedAt)) }
        for p in sparkPlays    { days.insert(cal.startOfDay(for: p.startedAt)) }
        return days.count
    }

    // MARK: - Private Helpers

    private func last7Days(anchor: Date) -> [Date] {
        let cal = Calendar.kst
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
