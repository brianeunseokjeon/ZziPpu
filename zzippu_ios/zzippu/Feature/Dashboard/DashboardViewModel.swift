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

    /// 수유량 추세 카드 기간 토글(7/14일). 웹 TrendRangeToggle 정합.
    var trendDayCount: Int = 7

    // 서버 집계 (오늘 일별 요약)
    var dailySummary:  DailySummary       = .empty
    var prediction:    FeedingPrediction  = .empty

    // 7일 스파크라인 원본 데이터 (카드 미니 그래프용)
    var sparkFeedings: [Feeding]     = []
    var sparkSleeps:   [SleepRecord] = []
    var sparkDiapers:  [DiaperRecord] = []
    var sparkPlays:    [PlayRecord]  = []

    // 수유량 추세 카드용 원본(최근 14일치 — 7/14 토글 모두 커버).
    var trendFeedings: [Feeding]     = []

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

    /// SWR 디스크 캐시 저장소(옵셔널 주입). nil이면 캐싱 이전과 완전 동일 동작.
    private let snapshotStore: DashboardSnapshotStore?

    // MARK: - UseCases (순수 집계)

    private let trendUseCase = ComputeTrendUseCase()
    private let feedingTrendUseCase = ComputeFeedingTrendUseCase()
    private let summaryUseCase = ComputeDashboardSummaryUseCase()
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
        babyId: UUID,
        snapshotStore: DashboardSnapshotStore? = nil
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
        self.snapshotStore       = snapshotStore
        self.insightsUseCase     = EvaluateInsightsUseCase(repository: guidelineRepository)
    }

    // MARK: - Actions

    func loadAll(for date: Date? = nil) {
        let target = date ?? selectedDate
        let isToday = Calendar.kst.isDateInToday(target)

        // SWR hydrate: 진입 초기(아직 데이터 없음) && 오늘 조회일 때만 디스크 스냅샷을 즉시 복원.
        // → dailySummary != .empty 가 되어 전체 스피너를 자연스럽게 스킵(콜드스타트 무-스피너).
        // store=nil 이면 이 블록은 통째로 no-op → 기존 동작과 바이트-동일.
        if isToday, dailySummary == .empty, let snapshot = snapshotStore?.load(babyId: babyId) {
            hydrate(from: snapshot)
        }

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

                // 수유량 추세(7/14 토글)용 14일치 수유 기록.
                async let tFeed = loadTrendFeedings(anchor: target)

                dailySummary  = try await summary
                prediction    = try await pred
                growthSeries  = try await growth
                activeBaby    = try await baby
                sparkFeedings = try await fAll
                sparkSleeps   = try await sAll
                sparkDiapers  = try await dAll
                sparkPlays    = try await pAll
                trendFeedings = try await tFeed

                recomputeInsights()

                // SWR save: fetch 성공 후 최신 상태를 오늘 날짜에 한해 스냅샷 저장.
                // 과거일 조회는 캐시 우회(오늘 데이터 오염 방지). store=nil 이면 no-op.
                if isToday { saveSnapshot() }

            } catch {
                // 실패해도 hydrate된 stale 데이터는 유지(사용자 경험 보호).
                errorMessage = "대시보드 로드 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - SWR Snapshot (디스크 캐시 hydrate/save)

    /// 디스크 스냅샷 → 표시 상태 복원 후 인사이트 재계산(동기).
    private func hydrate(from s: DashboardSnapshot) {
        dailySummary  = s.dailySummary
        prediction    = s.prediction
        growthSeries  = s.growthSeries
        sparkFeedings = s.sparkFeedings
        sparkSleeps   = s.sparkSleeps
        sparkDiapers  = s.sparkDiapers
        sparkPlays    = s.sparkPlays
        trendFeedings = s.trendFeedings
        activeBaby    = s.activeBaby
        recomputeInsights()
    }

    /// 현재 표시 상태를 스냅샷으로 묶어 백그라운드 저장(store=nil이면 no-op).
    private func saveSnapshot() {
        guard let store = snapshotStore else { return }
        let snapshot = DashboardSnapshot(
            dailySummary:  dailySummary,
            prediction:    prediction,
            growthSeries:  growthSeries,
            sparkFeedings: sparkFeedings,
            sparkSleeps:   sparkSleeps,
            sparkDiapers:  sparkDiapers,
            sparkPlays:    sparkPlays,
            trendFeedings: trendFeedings,
            activeBaby:    activeBaby,
            savedAt:       .now
        )
        store.save(snapshot, babyId: babyId)
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

    // MARK: - Computed: 도넛 세그먼트 (수유 타입별 / 기저귀 소·대)

    /// 선택 날짜의 수유 기록(sparkFeedings 7일치에서 필터).
    private var todayFeedings: [Feeding] {
        let cal = Calendar.kst
        let day = cal.startOfDay(for: selectedDate)
        return sparkFeedings.filter { cal.startOfDay(for: $0.startedAt) == day }
    }

    /// 수유 도넛 원천값(분유 ml : 모유 ml/회수). UI는 값만 받음.
    var feedingBreakdown: ComputeDashboardSummaryUseCase.FeedingBreakdown {
        summaryUseCase.feedingBreakdown(todayFeedings)
    }

    /// 수유 도넛: 분유 vs 모유. ml 우선, 모유 ml 미기록이면 회수 비중으로 폴백.
    var feedingDonutSegments: [(value: Double, isFormula: Bool, label: String)] {
        let b = feedingBreakdown
        // 둘 다 ml 있으면 ml 기준
        if b.formulaMl > 0 || b.breastMl > 0 {
            var segs: [(Double, Bool, String)] = []
            if b.formulaMl > 0 { segs.append((Double(b.formulaMl), true, "분유")) }
            if b.breastMl > 0 { segs.append((Double(b.breastMl), false, "모유")) }
            // 모유는 ml 없지만 회수는 있는 경우 — 최소 존재 표시(회수를 ml 대용 스케일)
            if b.breastMl == 0 && b.breastCount > 0 {
                segs.append((Double(b.breastCount), false, "모유"))
            }
            return segs.map { (value: $0.0, isFormula: $0.1, label: $0.2) }
        }
        // ml 전무 → 회수 비중
        var segs: [(Double, Bool, String)] = []
        if b.formulaCount > 0 { segs.append((Double(b.formulaCount), true, "분유")) }
        if b.breastCount > 0 { segs.append((Double(b.breastCount), false, "모유")) }
        return segs.map { (value: $0.0, isFormula: $0.1, label: $0.2) }
    }

    /// 수유 도넛 중앙 텍스트(총 ml 또는 총 회수).
    var feedingDonutCenter: (text: String, caption: String) {
        let ml = dailySummary.totalFeedingMl
        if ml > 0 { return ("\(ml)", "ml") }
        let cnt = dailySummary.feedingCount
        return cnt > 0 ? ("\(cnt)", "회") : ("—", "")
    }

    /// 기저귀 도넛: 소(pee) vs 대(poop). dailySummary에 이미 존재 → 매핑만.
    var diaperDonutSegments: [(value: Double, isPee: Bool, label: String)] {
        var segs: [(Double, Bool, String)] = []
        if dailySummary.peeCount > 0 { segs.append((Double(dailySummary.peeCount), true, "소변")) }
        if dailySummary.poopCount > 0 { segs.append((Double(dailySummary.poopCount), false, "대변")) }
        return segs.map { (value: $0.0, isPee: $0.1, label: $0.2) }
    }

    var diaperDonutCenter: (text: String, caption: String) {
        let total = dailySummary.diaperCount
        return total > 0 ? ("\(total)", "회") : ("—", "")
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

    // MARK: - Computed: 수유량 추세(7/14일 막대 차트)

    /// 현재 토글(trendDayCount) 기준 KST 일별 수유량 배열(요일 라벨·빈날 nil).
    var feedingTrendDays: [FeedingTrendDay] {
        feedingTrendUseCase(
            feedings: trendFeedings,
            dayCount: trendDayCount,
            anchorDate: selectedDate
        )
    }

    /// 수유량 추세 카드 권장선(min/max, ml). FeedingAdequacy 권장값 재사용. 없으면 nil → 선 생략.
    var feedingTrendGuideline: (min: Double, max: Double)? {
        guard let range = feedingRecommendedRange else { return nil }
        return (range.lowerBound, range.upperBound)
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

    /// 수유량 추세 카드용 최근 14일 수유 기록(7/14 토글 공용).
    private func loadTrendFeedings(anchor: Date) async throws -> [Feeding] {
        let cal = Calendar.kst
        let dates = (0..<14).compactMap { cal.date(byAdding: .day, value: -$0, to: anchor) }
        var all: [Feeding] = []
        for date in dates {
            let items = try await feedingRepository.list(babyId: babyId, on: date)
            all += items
        }
        return all
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
