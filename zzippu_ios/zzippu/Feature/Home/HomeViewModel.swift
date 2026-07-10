// Feature/Home/HomeViewModel.swift
// 홈 기록허브 ViewModel — 웹 홈(page.tsx) 재현:
//   • 여러 날 스크롤 피드(날짜 섹션: 오늘/어제/그제/"N월 N일 (요일)")
//   • 6버튼 퀵기록(분유·모유·소변·대변·수면시작·터미타임시작) + 활성세션(수면/터미타임)
//   • 과거 날짜 포커스 뷰
// Domain 프로토콜만 의존(클린아키텍처).

import Foundation
import Observation

@Observable
final class HomeViewModel {

    // MARK: - 상수
    static let maxDays = 60      // 웹 MAX_DAYS
    static let initialDays = 7   // 웹 초기 로드(오늘~6일 전)

    // MARK: - State

    var activeBaby: Baby?
    var selectedDate: Date = .now          // AppHeader 날짜 네비 + 과거 포커스 판별
    var isLoadingBaby: Bool = false
    var errorMessage: String?

    /// 날짜별(자정 기준) 로드된 기록. key = 자정 Date.
    private(set) var recordsByDay: [Date: DayRecords] = [:]

    /// 피드에 표시할 날짜 목록(오늘 → 과거 순, 자정 Date).
    private(set) var loadedDays: [Date] = []

    /// 진행중 세션(오늘 기준)
    var activeSleepSession: SleepRecord? = nil
    var activePlaySession:  PlayRecord?  = nil

    /// 마지막 분유량(퀵세이브 반복용). nil이면 기본값 사용.
    var lastFormulaMl: Int? = nil

    /// 과거 날짜 포커스 뷰 여부
    var isFocusingPast: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }

    // MARK: - Dependencies (Domain 프로토콜만)

    private let feedingRepository: FeedingRepository
    private let babyRepository: BabyRepository
    private let sleepRepository: SleepRepository
    private let diaperRepository: DiaperRepository
    private let playRepository: PlayRepository
    private let babyId: UUID

    // MARK: - Init

    init(
        feedingRepository: FeedingRepository,
        babyRepository: BabyRepository,
        sleepRepository: SleepRepository,
        diaperRepository: DiaperRepository,
        playRepository: PlayRepository,
        babyId: UUID
    ) {
        self.feedingRepository = feedingRepository
        self.babyRepository    = babyRepository
        self.sleepRepository   = sleepRepository
        self.diaperRepository  = diaperRepository
        self.playRepository    = playRepository
        self.babyId            = babyId
    }

    // MARK: - Baby

    func loadActiveBaby() {
        isLoadingBaby = true
        Task { @MainActor in
            defer { isLoadingBaby = false }
            do {
                activeBaby = try await babyRepository.fetch(id: babyId)
            } catch {
                errorMessage = "아기 정보 로드 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 초기/재로드

    /// 홈 진입 시: 오늘~초기N일 로드 + 활성 세션 로드.
    func loadInitial() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        loadedDays = (0..<Self.initialDays).compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }
        for day in loadedDays { loadDay(day) }
        refreshActiveSessions()
        refreshLastFormula()
    }

    /// 하위호환 (기존 loadAll/loadFeedings 호출부 방어)
    func loadAll(for date: Date? = nil) { loadInitial() }
    func loadFeedings(for date: Date? = nil) { loadInitial() }

    /// 피드 하단 도달 → 다음 과거 하루 append.
    func loadOlderDay() {
        guard loadedDays.count < Self.maxDays, let oldest = loadedDays.last else { return }
        guard let next = Calendar.current.date(byAdding: .day, value: -1, to: oldest) else { return }
        loadedDays.append(next)
        loadDay(next)
    }

    var reachedMaxDays: Bool { loadedDays.count >= Self.maxDays }

    /// AppHeader 날짜 변경 → 과거 포커스/오늘 전환.
    func changeDate(_ date: Date) {
        selectedDate = date
        let day = Calendar.current.startOfDay(for: date)
        loadDay(day)                 // 포커스 대상 일자 로드(캐시 없으면)
        if Calendar.current.isDateInToday(date) {
            refreshActiveSessions()
        }
    }

    // MARK: - 단일 일자 로드

    private func loadDay(_ day: Date) {
        // 이미 로드됐고 로딩중이 아니면 재요청 생략(초기엔 로딩표시 위해 nil placeholder)
        if recordsByDay[day] == nil {
            recordsByDay[day] = DayRecords(isLoading: true)
        }
        Task { @MainActor in
            do {
                async let f = feedingRepository.list(babyId: babyId, on: day)
                async let s = sleepRepository.list(babyId: babyId, on: day)
                async let d = diaperRepository.list(babyId: babyId, on: day)
                async let p = playRepository.list(babyId: babyId, on: day)
                let rec = DayRecords(
                    feedings: try await f,
                    sleeps:   try await s,
                    diapers:  try await d,
                    plays:    try await p,
                    isLoading: false
                )
                recordsByDay[day] = rec
            } catch {
                recordsByDay[day] = DayRecords(isLoading: false)
                errorMessage = "기록 로드 실패: \(error.localizedDescription)"
            }
        }
    }

    private func refreshActiveSessions() {
        Task { @MainActor in
            do {
                activeSleepSession = try await sleepRepository.activeSession(babyId: babyId)
            } catch { /* 무음: 배너만 안 뜸 */ }
        }
        // 활성 터미타임: 오늘 play 중 endedAt == nil.
        let today = Calendar.current.startOfDay(for: Date())
        activePlaySession = recordsByDay[today]?.plays.first { $0.endedAt == nil }
    }

    private func refreshLastFormula() {
        Task { @MainActor in
            if let last = try? await feedingRepository.lastFeeding(babyId: babyId),
               last.type == .formula, let ml = last.amountMl {
                lastFormulaMl = ml
            }
        }
    }

    // MARK: - 통합 타임라인 (일자별)

    /// 특정 일자의 통합 정렬 타임라인 아이템(최신순).
    func timelineItems(for day: Date) -> [TimelineItem] {
        guard let rec = recordsByDay[day] else { return [] }
        var items: [TimelineItem] = []
        items += rec.feedings.map { TimelineItem(from: $0) }
        items += rec.sleeps.map   { TimelineItem(from: $0) }
        items += rec.diapers.map  { TimelineItem(from: $0) }
        items += rec.plays.map    { TimelineItem(from: $0) }
        return items.sorted { $0.time > $1.time }
    }

    func isLoading(for day: Date) -> Bool {
        recordsByDay[day]?.isLoading ?? true
    }

    func isEmpty(for day: Date) -> Bool {
        guard let rec = recordsByDay[day], !rec.isLoading else { return false }
        return rec.feedings.isEmpty && rec.sleeps.isEmpty && rec.diapers.isEmpty && rec.plays.isEmpty
    }

    // MARK: - 퀵세이브 (오늘 기록)

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    /// 분유 원탭: 마지막 분유량(없으면 120ml) 반복.
    func quickSaveFormula() async -> String {
        let ml = lastFormulaMl ?? 120
        let feeding = Feeding.new(babyId: babyId, type: .formula, amountMl: ml, startedAt: .now)
        await insertFeeding(feeding)
        lastFormulaMl = ml
        return "분유 \(ml)ml 기록됐어요"
    }

    /// 소변 원탭.
    func quickSavePee() async -> String {
        let diaper = DiaperRecord.new(babyId: babyId, diaperType: .pee, recordedAt: .now)
        await insertDiaper(diaper)
        return "소변 기록됐어요"
    }

    // MARK: - 활성 세션 토글

    /// 수면 시작/종료. 반환 = 토스트 메시지.
    func toggleSleep() async -> String {
        if let active = activeSleepSession {
            await endSleep(active)
            return "수면 종료됐어요"
        } else {
            let sleep = SleepRecord.new(babyId: babyId, startedAt: .now)
            await insertSleep(sleep, markActive: true)
            return "수면 타이머 시작됐어요"
        }
    }

    /// 터미타임 시작/종료. 반환 = 토스트 메시지.
    func togglePlay() async -> String {
        if let active = activePlaySession {
            await endPlay(active)
            return "터미타임 종료됐어요"
        } else {
            let play = PlayRecord.new(babyId: babyId, playType: .tummyTime, startedAt: .now)
            await insertPlay(play, markActive: true)
            return "터미타임 타이머 시작됐어요"
        }
    }

    // MARK: - 시트 저장 콜백 (모유/대변 상세, 과거 날짜 입력)

    func saveFeeding(_ feeding: Feeding) async {
        await insertFeeding(feeding)
        if feeding.type == .formula, let ml = feeding.amountMl { lastFormulaMl = ml }
    }
    func saveSleep(_ sleep: SleepRecord) async {
        await insertSleep(sleep, markActive: sleep.endedAt == nil && Calendar.current.isDateInToday(sleep.startedAt))
    }
    func saveDiaper(_ diaper: DiaperRecord) async { await insertDiaper(diaper) }
    func savePlay(_ play: PlayRecord) async {
        await insertPlay(play, markActive: play.endedAt == nil && Calendar.current.isDateInToday(play.startedAt))
    }

    // MARK: - 낙관적 삽입 헬퍼

    @MainActor
    private func dayKey(for date: Date) -> Date { Calendar.current.startOfDay(for: date) }

    @MainActor
    private func mutate(_ day: Date, _ block: (inout DayRecords) -> Void) {
        var rec = recordsByDay[day] ?? DayRecords(isLoading: false)
        block(&rec)
        recordsByDay[day] = rec
    }

    private func insertFeeding(_ feeding: Feeding) async {
        let day = await dayKey(for: feeding.startedAt)
        await mutate(day) { $0.feedings.insert(feeding, at: 0) }
        do {
            let confirmed = try await feedingRepository.create(feeding)
            await mutate(day) { r in
                if let i = r.feedings.firstIndex(where: { $0.id == feeding.id }) { r.feedings[i] = confirmed }
            }
        } catch {
            await mutate(day) { $0.feedings.removeAll { $0.id == feeding.id } }
            await MainActor.run { errorMessage = "수유 저장 실패: \(error.localizedDescription)" }
        }
    }

    private func insertDiaper(_ diaper: DiaperRecord) async {
        let day = await dayKey(for: diaper.recordedAt)
        await mutate(day) { $0.diapers.insert(diaper, at: 0) }
        do {
            let confirmed = try await diaperRepository.create(diaper)
            await mutate(day) { r in
                if let i = r.diapers.firstIndex(where: { $0.id == diaper.id }) { r.diapers[i] = confirmed }
            }
        } catch {
            await mutate(day) { $0.diapers.removeAll { $0.id == diaper.id } }
            await MainActor.run { errorMessage = "기저귀 저장 실패: \(error.localizedDescription)" }
        }
    }

    private func insertSleep(_ sleep: SleepRecord, markActive: Bool) async {
        let day = await dayKey(for: sleep.startedAt)
        await mutate(day) { $0.sleeps.insert(sleep, at: 0) }
        if markActive { await MainActor.run { activeSleepSession = sleep } }
        do {
            let confirmed = try await sleepRepository.create(sleep)
            await mutate(day) { r in
                if let i = r.sleeps.firstIndex(where: { $0.id == sleep.id }) { r.sleeps[i] = confirmed }
            }
            if markActive { await MainActor.run { activeSleepSession = confirmed } }
        } catch {
            await mutate(day) { $0.sleeps.removeAll { $0.id == sleep.id } }
            if markActive { await MainActor.run { activeSleepSession = nil } }
            await MainActor.run { errorMessage = "수면 저장 실패: \(error.localizedDescription)" }
        }
    }

    private func insertPlay(_ play: PlayRecord, markActive: Bool) async {
        let day = await dayKey(for: play.startedAt)
        await mutate(day) { $0.plays.insert(play, at: 0) }
        if markActive { await MainActor.run { activePlaySession = play } }
        do {
            let confirmed = try await playRepository.create(play)
            await mutate(day) { r in
                if let i = r.plays.firstIndex(where: { $0.id == play.id }) { r.plays[i] = confirmed }
            }
            if markActive { await MainActor.run { activePlaySession = confirmed } }
        } catch {
            await mutate(day) { $0.plays.removeAll { $0.id == play.id } }
            if markActive { await MainActor.run { activePlaySession = nil } }
            await MainActor.run { errorMessage = "놀이 저장 실패: \(error.localizedDescription)" }
        }
    }

    // MARK: - 종료

    private func endSleep(_ active: SleepRecord) async {
        let day = await dayKey(for: active.startedAt)
        let now = Date.now
        var ended = active; ended.endedAt = now
        await mutate(day) { r in
            if let i = r.sleeps.firstIndex(where: { $0.id == active.id }) { r.sleeps[i] = ended }
        }
        await MainActor.run { activeSleepSession = nil }
        do {
            let confirmed = try await sleepRepository.endSleep(id: active.id, babyId: active.babyId, endedAt: now)
            await mutate(day) { r in
                if let i = r.sleeps.firstIndex(where: { $0.id == confirmed.id }) { r.sleeps[i] = confirmed }
            }
        } catch {
            await mutate(day) { r in
                if let i = r.sleeps.firstIndex(where: { $0.id == active.id }) { r.sleeps[i] = active }
            }
            await MainActor.run {
                activeSleepSession = active
                errorMessage = "수면 종료 실패: \(error.localizedDescription)"
            }
        }
    }

    /// 터미타임 종료: PlayRepository에 end API가 없어 delete + endedAt 포함 재생성.
    private func endPlay(_ active: PlayRecord) async {
        let day = await dayKey(for: active.startedAt)
        let now = Date.now
        let minutes = max(0, Int(now.timeIntervalSince(active.startedAt) / 60))
        let ended = PlayRecord.new(
            babyId: active.babyId, playType: active.playType,
            startedAt: active.startedAt, endedAt: now,
            durationMinutes: minutes, memo: active.memo
        )
        // 낙관적: 기존 제거 후 종료본 삽입
        await mutate(day) { r in
            r.plays.removeAll { $0.id == active.id }
            r.plays.insert(ended, at: 0)
        }
        await MainActor.run { activePlaySession = nil }
        do {
            try await playRepository.delete(id: active.id, babyId: active.babyId)
            let confirmed = try await playRepository.create(ended)
            await mutate(day) { r in
                if let i = r.plays.firstIndex(where: { $0.id == ended.id }) { r.plays[i] = confirmed }
            }
        } catch {
            await mutate(day) { r in
                r.plays.removeAll { $0.id == ended.id }
                r.plays.insert(active, at: 0)
            }
            await MainActor.run {
                activePlaySession = active
                errorMessage = "터미타임 종료 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 삭제

    func delete(_ item: TimelineItem, on day: Date) {
        let key = Calendar.current.startOfDay(for: day)
        switch item.domainKind {
        case .feedingFormula, .feedingBreastLeft, .feedingBreastRight, .feedingBreastBoth, .feedingSolids:
            guard let f = recordsByDay[key]?.feedings.first(where: { $0.id == item.id }) else { return }
            recordsByDay[key]?.feedings.removeAll { $0.id == f.id }
            Task { @MainActor in
                do { try await feedingRepository.delete(id: f.id, babyId: f.babyId) }
                catch { recordsByDay[key]?.feedings.insert(f, at: 0); errorMessage = "삭제 실패: \(error.localizedDescription)" }
            }
        case .sleep:
            guard let s = recordsByDay[key]?.sleeps.first(where: { $0.id == item.id }) else { return }
            recordsByDay[key]?.sleeps.removeAll { $0.id == s.id }
            if activeSleepSession?.id == s.id { activeSleepSession = nil }
            Task { @MainActor in
                do { try await sleepRepository.delete(id: s.id, babyId: s.babyId) }
                catch { recordsByDay[key]?.sleeps.insert(s, at: 0); errorMessage = "삭제 실패: \(error.localizedDescription)" }
            }
        case .diaperPee, .diaperPoop, .diaperBoth:
            guard let d = recordsByDay[key]?.diapers.first(where: { $0.id == item.id }) else { return }
            recordsByDay[key]?.diapers.removeAll { $0.id == d.id }
            Task { @MainActor in
                do { try await diaperRepository.delete(id: d.id, babyId: d.babyId) }
                catch { recordsByDay[key]?.diapers.insert(d, at: 0); errorMessage = "삭제 실패: \(error.localizedDescription)" }
            }
        case .play:
            guard let p = recordsByDay[key]?.plays.first(where: { $0.id == item.id }) else { return }
            recordsByDay[key]?.plays.removeAll { $0.id == p.id }
            if activePlaySession?.id == p.id { activePlaySession = nil }
            Task { @MainActor in
                do { try await playRepository.delete(id: p.id, babyId: p.babyId) }
                catch { recordsByDay[key]?.plays.insert(p, at: 0); errorMessage = "삭제 실패: \(error.localizedDescription)" }
            }
        }
    }
}

// MARK: - DayRecords (한 날짜의 4종 기록 묶음)

struct DayRecords {
    var feedings: [Feeding] = []
    var sleeps:   [SleepRecord] = []
    var diapers:  [DiaperRecord] = []
    var plays:    [PlayRecord] = []
    var isLoading: Bool = false
}

// MARK: - TimelineItem (통합 타임라인 행)

struct TimelineItem: Identifiable {
    let id: UUID
    let time: Date
    let label: String
    let domainKind: DomainKind

    init(from feeding: Feeding) {
        self.id = feeding.id
        self.time = feeding.startedAt
        self.label = feeding.timelineLabel
        self.domainKind = feeding.domainKind
    }
    init(from sleep: SleepRecord) {
        self.id = sleep.id
        self.time = sleep.startedAt
        self.label = sleep.timelineLabel
        self.domainKind = .sleep
    }
    init(from diaper: DiaperRecord) {
        self.id = diaper.id
        self.time = diaper.recordedAt
        self.label = diaper.timelineLabel
        self.domainKind = diaper.domainKind
    }
    init(from play: PlayRecord) {
        self.id = play.id
        self.time = play.startedAt
        self.label = play.timelineLabel
        self.domainKind = .play
    }
}

// MARK: - Domain Label Helpers (Feature 레이어)

extension Feeding {
    var timelineLabel: String {
        switch type {
        case .formula:     return amountMl.map { "분유 \($0)ml" } ?? "분유"
        case .breastLeft:  return durationMinutes.map { "모유 왼쪽 (\($0)분)" } ?? "모유 왼쪽"
        case .breastRight: return durationMinutes.map { "모유 오른쪽 (\($0)분)" } ?? "모유 오른쪽"
        case .breastBoth:  return durationMinutes.map { "모유 양쪽 (\($0)분)" } ?? "모유 양쪽"
        }
    }
    var domainKind: DomainKind {
        switch type {
        case .formula:     return .feedingFormula
        case .breastLeft:  return .feedingBreastLeft
        case .breastRight: return .feedingBreastRight
        case .breastBoth:  return .feedingBreastBoth
        }
    }
}

extension SleepRecord {
    var timelineLabel: String {
        if isActive { return "수면 중 · \(elapsedMinutes())분 경과" }
        if let min = durationMinutes {
            let h = min / 60, m = min % 60
            if h > 0 { return "수면 (\(h)시간\(m > 0 ? " \(m)분" : ""))" }
            return "수면 (\(m)분)"
        }
        return "수면 시작"
    }
}

extension DiaperRecord {
    var timelineLabel: String {
        var label = diaperType.displayName
        if let color = stoolColor { label += " · \(color.displayName)" }
        return label
    }
    var domainKind: DomainKind {
        switch diaperType {
        case .pee:  return .diaperPee
        case .poo:  return .diaperPoop
        case .both: return .diaperBoth
        }
    }
}

extension PlayRecord {
    var timelineLabel: String {
        if endedAt == nil { return "\(playType.displayName) 시작" }
        if let min = durationMinutes, min > 0 {
            let h = min / 60, m = min % 60
            if h > 0 { return "\(playType.displayName) (\(h)시간\(m > 0 ? " \(m)분" : ""))" }
            return "\(playType.displayName) (\(m)분)"
        }
        return playType.displayName
    }
}

// MARK: - Baby → AppHeaderBaby

extension Baby {
    func toHeaderBaby() -> AppHeaderBaby {
        let gender: BabyGender
        switch self.gender {
        case .male:    gender = .male
        case .female:  gender = .female
        case .unknown: gender = .unknown
        }
        let photoURL: URL? = photoUrl.flatMap { URL(string: $0) }
        return AppHeaderBaby(name: name, birthDate: birthDate, gender: gender, photoURL: photoURL)
    }
}
