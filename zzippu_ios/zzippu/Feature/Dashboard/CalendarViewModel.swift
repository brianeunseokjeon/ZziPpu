// Feature/Dashboard/CalendarViewModel.swift
// 달력 상태 관리 ViewModel — 현재 월·이동·월 캐시.
// Domain 프로토콜만 의존(클린아키텍처). @Observable.

import Foundation
import Observation

@Observable
final class CalendarViewModel {

    // MARK: - State

    /// 현재 표시 중인 달의 임의 날짜 (내부에서 첫날 정규화됨)
    private(set) var currentMonth: Date = Date.now
    private(set) var calendarModel: MonthCalendarModel = .empty
    private(set) var isLoading: Bool = false

    // MARK: - Navigation Bounds

    private var baby: Baby?

    /// 하한: 아기 생일이 속한 달 (이전으로 이동 불가)
    private var lowerBound: Date {
        guard let b = baby else { return currentMonth }
        let cal = Calendar.kst
        let comps = cal.dateComponents([.year, .month], from: b.birthDate)
        return cal.date(from: comps) ?? currentMonth
    }

    /// 상한: 8차 검진 end 이후 달까지 (최소 오늘 달 이후 충분히 열어둠)
    private var upperBound: Date {
        guard let b = baby else {
            return Calendar.kst.date(byAdding: .month, value: 24, to: Date.now) ?? Date.now
        }
        // 8차 end = 생일 + 72개월 - 1일 → 그 달
        let cal = Calendar.kst
        let eightChEnd = cal.date(byAdding: .month, value: 72, to: b.birthDate) ?? Date.now
        let eightChMonth = cal.date(from: cal.dateComponents([.year, .month], from: eightChEnd)) ?? Date.now
        // 최소 오늘+12개월 보장
        let minUpper = cal.date(byAdding: .month, value: 12, to: Date.now) ?? Date.now
        return eightChMonth > minUpper ? eightChMonth : minUpper
    }

    var canGoPrevious: Bool {
        let cal = Calendar.kst
        let lower = cal.date(from: cal.dateComponents([.year, .month], from: lowerBound)) ?? lowerBound
        let current = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) ?? currentMonth
        return current > lower
    }

    var canGoNext: Bool {
        let cal = Calendar.kst
        let upper = cal.date(from: cal.dateComponents([.year, .month], from: upperBound)) ?? upperBound
        let current = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) ?? currentMonth
        return current < upper
    }

    var isShowingToday: Bool {
        Calendar.kst.isDate(currentMonth, equalTo: Date.now, toGranularity: .month)
    }

    // MARK: - Month Cache (month → MonthCalendarModel)
    private var monthCache: [Date: MonthCalendarModel] = [:]

    // MARK: - Dependencies

    private let buildCalendar: BuildMonthCalendarUseCase
    private let babyRepository: BabyRepository
    private let babyId: UUID

    // MARK: - Init

    init(
        feedingRepository: FeedingRepository,
        babyRepository:    BabyRepository,
        babyId:            UUID
    ) {
        self.babyRepository = babyRepository
        self.babyId         = babyId

        let feedingProvider  = FeedingVolumeDecorationProvider(feedingRepository: feedingRepository)
        let checkupProvider  = CheckupDecorationProvider()

        self.buildCalendar = BuildMonthCalendarUseCase(
            providers: [feedingProvider, checkupProvider]
        )
    }

    // MARK: - Actions

    func loadBaby() {
        Task { @MainActor in
            baby = try? await babyRepository.fetch(id: babyId)
            await loadCurrentMonth()
        }
    }

    func goToPreviousMonth() {
        guard canGoPrevious else { return }
        let cal = Calendar.kst
        if let prev = cal.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = prev
            Task { @MainActor in await loadCurrentMonth() }
        }
    }

    func goToNextMonth() {
        guard canGoNext else { return }
        let cal = Calendar.kst
        if let next = cal.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = next
            Task { @MainActor in await loadCurrentMonth() }
        }
    }

    func goToToday() {
        currentMonth = Date.now
        Task { @MainActor in await loadCurrentMonth() }
    }

    /// 새 기록 저장 후 해당 월 캐시 무효화 → 다음 로드 시 재계산.
    func invalidateCurrentMonthCache() {
        let cacheKey = cacheKey(for: currentMonth)
        monthCache.removeValue(forKey: cacheKey)
        Task { @MainActor in await loadCurrentMonth() }
    }

    // MARK: - Private

    private func loadCurrentMonth() async {
        guard let baby else {
            isLoading = false
            return
        }

        let key = cacheKey(for: currentMonth)
        if let cached = monthCache[key] {
            calendarModel = cached
            return
        }

        isLoading = true
        let model = await buildCalendar(month: currentMonth, baby: baby)
        monthCache[key] = model
        calendarModel = model
        isLoading = false
    }

    private func cacheKey(for month: Date) -> Date {
        let cal = Calendar.kst
        return cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
    }
}
