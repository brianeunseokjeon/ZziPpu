// Feature/Dashboard/CalendarViewModel.swift
// 달력 상태 관리 ViewModel — 현재 월·이동·월 캐시 + SWR 디스크 스냅샷.
// Domain 프로토콜만 의존(클린아키텍처). @Observable.
//
// SWR 캐싱(옵션 B):
//   월 진입 → 디스크 스냅샷 즉시 hydrate(무-스피너) → 백그라운드 dailyTotals 재조회
//   → 모델 재빌드(SwiftUI가 바뀐 셀만 재렌더) → 메모리캐시 갱신 + 스냅샷 save.
// 검진 데코는 생일 기반 순수계산 → 캐시 금지, 항상 재계산·합성.
// 결합도↓: snapshotStore 옵셔널 주입. nil이면 현행 메모리캐시 동작과 바이트-동일.

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

    /// 과거 월은 이번 세션에서 1회 재대조하면 이후 스킵(변동 드묾 — 제안서 §3.5).
    private var revalidatedPastMonths: Set<Date> = []

    // MARK: - Dependencies

    private let feedingRepository: FeedingRepository
    private let checkupProvider: CalendarDecorationProvider
    private let babyRepository: BabyRepository
    private let babyId: UUID

    /// SWR 디스크 스냅샷 저장소 — nil이면 순수 메모리캐시(현행) 동작.
    private let snapshotStore: CalendarSnapshotStore?

    // MARK: - Init

    init(
        feedingRepository: FeedingRepository,
        babyRepository:    BabyRepository,
        babyId:            UUID,
        snapshotStore:     CalendarSnapshotStore? = nil
    ) {
        self.feedingRepository = feedingRepository
        self.babyRepository    = babyRepository
        self.babyId            = babyId
        self.snapshotStore     = snapshotStore
        self.checkupProvider   = CheckupDecorationProvider()
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

    /// 새 기록 저장/당겨서새로고침 후 현재 월 무효화 → 재조회.
    /// 재조회 성공 시 스냅샷도 최신 volumes 로 save 되어 디스크 캐시까지 갱신됨(제안서 §3.4).
    func invalidateCurrentMonthCache() {
        let key = cacheKey(for: currentMonth)
        monthCache.removeValue(forKey: key)
        revalidatedPastMonths.remove(key)
        Task { @MainActor in await loadCurrentMonth() }
    }

    // MARK: - Load (hydrate → fetch → save)

    private func loadCurrentMonth() async {
        guard let baby else {
            isLoading = false
            return
        }

        let key       = cacheKey(for: currentMonth)
        let isToday   = Calendar.kst.isDate(currentMonth, equalTo: Date.now, toGranularity: .month)

        // (a) 메모리 히트: 즉시 사용. 오늘 월(변동 활발)은 그래도 백그라운드 재대조.
        if let cached = monthCache[key] {
            calendarModel = cached
            if isToday {
                await revalidate(baby: baby, month: currentMonth, key: key)
            }
            return
        }

        // (b) 메모리 미스 + 디스크 스냅샷 히트: 네트워크 없이 즉시 표시(스피너 회피).
        if let snap = snapshotStore?.load(babyId: babyId, month: currentMonth) {
            let volumes = snap.volumes.map { DateVolume(day: $0.day, totalMl: $0.totalMl) }
            let model   = await buildModel(month: currentMonth, baby: baby, volumes: volumes)
            monthCache[key] = model
            calendarModel   = model
            isLoading       = false
            // 이후 즉시 백그라운드 재대조로 최신화(과거 월은 세션 1회).
            if isToday || !revalidatedPastMonths.contains(key) {
                await revalidate(baby: baby, month: currentMonth, key: key)
            }
            return
        }

        // (c) 캐시 전무: 현행처럼 fetch(스피너).
        isLoading = true
        await revalidate(baby: baby, month: currentMonth, key: key)
        isLoading = false
    }

    /// 백그라운드 재대조: dailyTotals 새로 받아 모델 재빌드 → 캐시·모델 갱신 → 스냅샷 save.
    /// 실패 시 기존(hydrate/캐시) 표시 유지(대시보드 SWR 정책과 동일).
    private func revalidate(baby: Baby, month: Date, key: Date) async {
        guard let volumes = await fetchVolumes(month: month, baby: baby) else { return }

        let model = await buildModel(month: month, baby: baby, volumes: volumes)
        monthCache[key] = model
        calendarModel   = model
        revalidatedPastMonths.insert(key)

        snapshotStore?.save(
            CalendarMonthSnapshot(
                month:   key,
                volumes: volumes.map { DateVolumeSnapshot(day: $0.day, totalMl: $0.totalMl) },
                savedAt: Date.now
            ),
            babyId: babyId,
            month:  month
        )
    }

    // MARK: - Build

    /// 주입받은 총량(캐시 또는 재조회) + 검진(항상 계산)으로 MonthCalendarModel 조립.
    /// 그리드/검진/배너 로직은 BuildMonthCalendarUseCase 를 그대로 재사용(중복 없음).
    private func buildModel(month: Date, baby: Baby, volumes: [DateVolume]) async -> MonthCalendarModel {
        let builder = BuildMonthCalendarUseCase(
            providers: [StaticVolumeDecorationProvider(volumes: volumes), checkupProvider]
        )
        return await builder(month: month, baby: baby)
    }

    /// 월 42칸 범위 수유 총량 조회 (offline=로컬 SwiftData, serverOnly=API). 실패 → nil.
    private func fetchVolumes(month: Date, baby: Baby) async -> [DateVolume]? {
        let cal   = Calendar.kst
        let days  = make42Days(for: month)
        guard let first = days.first, let last = days.last else { return nil }
        let start = cal.startOfDay(for: first)
        let end   = cal.startOfDay(for: last)
        return try? await feedingRepository.dailyTotals(babyId: baby.id, from: start, to: end)
    }

    // MARK: - Helpers

    /// BuildMonthCalendarUseCase 와 동일 규칙의 42칸 범위 (수유 조회 범위 산정용).
    private func make42Days(for month: Date) -> [Date] {
        var cal = Calendar.kst
        cal.firstWeekday = 1
        let comps    = cal.dateComponents([.year, .month], from: month)
        guard let firstDay = cal.date(from: comps) else { return [] }
        let weekday   = cal.component(.weekday, from: firstDay)
        let offset    = weekday - 1
        guard let gridStart = cal.date(byAdding: .day, value: -offset, to: firstDay) else { return [] }
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private func cacheKey(for month: Date) -> Date {
        let cal = Calendar.kst
        return cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
    }
}
