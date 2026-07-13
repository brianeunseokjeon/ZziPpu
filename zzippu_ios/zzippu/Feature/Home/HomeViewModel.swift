// Feature/Home/HomeViewModel.swift
// 홈 기록허브 ViewModel — 웹 홈(page.tsx) 재현:
//   • 여러 날 스크롤 피드(날짜 섹션: 오늘/어제/그제/"N월 N일 (요일)")
//   • 6버튼 퀵기록(분유·모유·소변·대변·수면시작·터미타임) + 활성세션(수면). 터미타임=즉시기록.
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
        !Calendar.kst.isDateInToday(selectedDate)
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
        let cal = Calendar.kst
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
        guard let next = Calendar.kst.date(byAdding: .day, value: -1, to: oldest) else { return }
        loadedDays.append(next)
        loadDay(next)
    }

    var reachedMaxDays: Bool { loadedDays.count >= Self.maxDays }

    /// AppHeader 날짜 변경 → 과거 포커스/오늘 전환.
    func changeDate(_ date: Date) {
        selectedDate = date
        let day = Calendar.kst.startOfDay(for: date)
        loadDay(day)                 // 포커스 대상 일자 로드(캐시 없으면)
        if Calendar.kst.isDateInToday(date) {
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

    /// "최근" 활성으로 인정할 최대 경과(초). 이보다 오래된 미종료 세션은
    /// 과거 테스트 잔재·종료 누락으로 보고 활성 배너로 띄우지 않는다(웹과 동일한 24h 기준).
    private static let activeStaleThreshold: TimeInterval = 24 * 60 * 60

    /// 미종료 세션이 "최근(활성)"인지 판정. 시작이 24h 이내여야 활성으로 취급.
    private func isRecentlyActive(startedAt: Date, now: Date = .now) -> Bool {
        let elapsed = now.timeIntervalSince(startedAt)
        return elapsed >= 0 && elapsed <= Self.activeStaleThreshold
    }

    private func refreshActiveSessions() {
        Task { @MainActor in
            do {
                let fetched = try await sleepRepository.activeSession(babyId: babyId)
                // 서버에 종료 안 된 오래된 수면(테스트 잔재)이 있어도 최근일 때만 활성 배너.
                if let s = fetched, isRecentlyActive(startedAt: s.startedAt) {
                    activeSleepSession = s
                } else {
                    activeSleepSession = nil
                }
            } catch { /* 무음: 배너만 안 뜸 */ }
        }
        // 터미타임은 즉시 기록(분유처럼 시점만) → 활성 세션 개념 없음.
        activePlaySession = nil
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

    private var today: Date { Calendar.kst.startOfDay(for: Date()) }

    /// 분유 원탭: 마지막 분유량(없으면 120ml) 반복.
    func quickSaveFormula() async -> String {
        let ml = lastFormulaMl ?? 120
        let feeding = Feeding.new(babyId: babyId, type: .formula, amountMl: ml, startedAt: .now)
        await insertFeeding(feeding)
        lastFormulaMl = ml
        return "분유 \(ml)ml 기록됐어요"
    }

    /// 소변 원탭 — 양 기본 "보통".
    func quickSavePee() async -> String {
        let diaper = DiaperRecord.new(babyId: babyId, diaperType: .pee, recordedAt: .now,
                                      amount: .normal)
        await insertDiaper(diaper)
        return "소변 기록됐어요"
    }

    /// 대변 원탭 — 그냥 누르면 기본 보통/보통/보통(양·질감·색). 상세는 행 탭 모달에서 수정.
    func quickSavePoo() async -> String {
        let diaper = DiaperRecord.new(babyId: babyId, diaperType: .poo, recordedAt: .now,
                                      stoolColor: .brown, stoolState: .normal, amount: .normal)
        await insertDiaper(diaper)
        return "대변 기록됐어요"
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

    /// 터미타임 즉시 기록 — 분유처럼 "언제 했는지" 시점만 남긴다(타이머·기간 없음).
    /// 반환 = 토스트 메시지.
    func recordPlay() async -> String {
        let play = PlayRecord.new(babyId: babyId, playType: .tummyTime, startedAt: .now)
        await insertPlay(play, markActive: false)
        return "터미타임 기록됐어요"
    }

    // MARK: - 시트 저장 콜백 (모유/대변 상세, 과거 날짜 입력)

    func saveFeeding(_ feeding: Feeding) async {
        await insertFeeding(feeding)
        if feeding.type == .formula, let ml = feeding.amountMl { lastFormulaMl = ml }
    }
    func saveSleep(_ sleep: SleepRecord) async {
        await insertSleep(sleep, markActive: sleep.endedAt == nil && Calendar.kst.isDateInToday(sleep.startedAt))
    }
    func saveDiaper(_ diaper: DiaperRecord) async { await insertDiaper(diaper) }
    func savePlay(_ play: PlayRecord) async {
        await insertPlay(play, markActive: play.endedAt == nil && Calendar.kst.isDateInToday(play.startedAt))
    }

    // MARK: - 낙관적 삽입 헬퍼

    @MainActor
    private func dayKey(for date: Date) -> Date { Calendar.kst.startOfDay(for: date) }

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

    // (터미타임은 즉시 기록으로 전환 — 시작/종료 타이머 폐기. endPlay 제거.)

    // MARK: - 편집 대상 조회

    /// 타임라인 아이템 → 편집용 도메인 원본(현재 필드값 포함).
    func editableRecord(for item: TimelineItem, on day: Date) -> EditableRecord? {
        let key = Calendar.kst.startOfDay(for: day)
        guard let rec = recordsByDay[key] else { return nil }
        switch item.domainKind {
        case .feedingFormula, .feedingBreastLeft, .feedingBreastRight, .feedingBreastBoth, .feedingSolids:
            return rec.feedings.first { $0.id == item.id }.map(EditableRecord.feeding)
        case .sleep:
            return rec.sleeps.first { $0.id == item.id }.map(EditableRecord.sleep)
        case .diaperPee, .diaperPoop, .diaperBoth:
            return rec.diapers.first { $0.id == item.id }.map(EditableRecord.diaper)
        case .play:
            return rec.plays.first { $0.id == item.id }.map(EditableRecord.play)
        case .checkup:
            return nil   // 검진은 타임라인 편집 없음(달력 표시 전용)
        }
    }

    // MARK: - 편집 저장 (웹 RecordEditSheet 재현)
    //   • feeding: PATCH(update) 낙관적 반영
    //   • diaper/sleep/play: PATCH 없음 → 삭제 후 재생성(웹과 동일 전략)
    //   실패 시 원본 롤백 + 에러 표기.

    /// 분유·모유 수정. feeding.startedAt 기준 일자에 반영.
    func updateFeeding(_ updated: Feeding) async {
        let day = await dayKey(for: updated.startedAt)
        // 원본(롤백용) 확보
        let original = recordsByDay[day]?.feedings.first { $0.id == updated.id }
        await mutate(day) { r in
            if let i = r.feedings.firstIndex(where: { $0.id == updated.id }) { r.feedings[i] = updated }
        }
        do {
            let confirmed = try await feedingRepository.update(updated)
            await mutate(day) { r in
                if let i = r.feedings.firstIndex(where: { $0.id == updated.id }) { r.feedings[i] = confirmed }
            }
            if confirmed.type == .formula, let ml = confirmed.amountMl { lastFormulaMl = ml }
        } catch {
            await mutate(day) { r in
                if let orig = original, let i = r.feedings.firstIndex(where: { $0.id == updated.id }) { r.feedings[i] = orig }
            }
            await MainActor.run { errorMessage = "수정 실패: \(error.localizedDescription)" }
        }
    }

    /// 배변 수정 — PATCH 없음: 삭제→재생성. recordedAt 기준 일자에 반영.
    func replaceDiaper(oldId: UUID, with new: DiaperRecord) async {
        let day = await dayKey(for: new.recordedAt)
        let original = recordsByDay[day]?.diapers.first { $0.id == oldId }
        await mutate(day) { r in
            r.diapers.removeAll { $0.id == oldId }
            r.diapers.insert(new, at: 0)
        }
        do {
            try await diaperRepository.delete(id: oldId, babyId: new.babyId)
            let confirmed = try await diaperRepository.create(new)
            await mutate(day) { r in
                if let i = r.diapers.firstIndex(where: { $0.id == new.id }) { r.diapers[i] = confirmed }
            }
        } catch {
            await mutate(day) { r in
                r.diapers.removeAll { $0.id == new.id }
                if let orig = original { r.diapers.insert(orig, at: 0) }
            }
            await MainActor.run { errorMessage = "수정 실패: \(error.localizedDescription)" }
        }
    }

    /// 수면 수정 — PATCH 없음: 삭제→재생성(+종료). startedAt 기준 일자에 반영.
    func replaceSleep(oldId: UUID, startedAt: Date, endedAt: Date?) async {
        let day = await dayKey(for: startedAt)
        let original = recordsByDay[day]?.sleeps.first { $0.id == oldId }
        let babyIdForRec = original?.babyId ?? babyId
        let placeholder = SleepRecord.new(babyId: babyIdForRec, startedAt: startedAt)
        let optimistic: SleepRecord = {
            var s = placeholder
            s.endedAt = endedAt
            if let e = endedAt { s.durationMinutes = max(0, Int(e.timeIntervalSince(startedAt) / 60)) }
            return s
        }()
        await mutate(day) { r in
            r.sleeps.removeAll { $0.id == oldId }
            r.sleeps.insert(optimistic, at: 0)
        }
        if activeSleepSession?.id == oldId {
            await MainActor.run { activeSleepSession = endedAt == nil ? optimistic : nil }
        }
        do {
            try await sleepRepository.delete(id: oldId, babyId: babyIdForRec)
            var created = try await sleepRepository.create(placeholder)
            if let e = endedAt {
                created = try await sleepRepository.endSleep(id: created.id, babyId: babyIdForRec, endedAt: e)
            }
            let confirmed = created
            await mutate(day) { r in
                if let i = r.sleeps.firstIndex(where: { $0.id == optimistic.id }) { r.sleeps[i] = confirmed }
            }
            if endedAt == nil { await MainActor.run { activeSleepSession = confirmed } }
        } catch {
            await mutate(day) { r in
                r.sleeps.removeAll { $0.id == optimistic.id }
                if let orig = original { r.sleeps.insert(orig, at: 0) }
            }
            await MainActor.run {
                if original?.endedAt == nil { activeSleepSession = original }
                errorMessage = "수정 실패: \(error.localizedDescription)"
            }
        }
    }

    /// 놀이 수정 — PATCH 없음: 삭제→재생성. startedAt 기준 일자에 반영.
    func replacePlay(oldId: UUID, with new: PlayRecord) async {
        let day = await dayKey(for: new.startedAt)
        let original = recordsByDay[day]?.plays.first { $0.id == oldId }
        await mutate(day) { r in
            r.plays.removeAll { $0.id == oldId }
            r.plays.insert(new, at: 0)
        }
        if activePlaySession?.id == oldId {
            await MainActor.run { activePlaySession = new.endedAt == nil ? new : nil }
        }
        do {
            try await playRepository.delete(id: oldId, babyId: new.babyId)
            let confirmed = try await playRepository.create(new)
            await mutate(day) { r in
                if let i = r.plays.firstIndex(where: { $0.id == new.id }) { r.plays[i] = confirmed }
            }
            if new.endedAt == nil { await MainActor.run { activePlaySession = confirmed } }
        } catch {
            await mutate(day) { r in
                r.plays.removeAll { $0.id == new.id }
                if let orig = original { r.plays.insert(orig, at: 0) }
            }
            await MainActor.run {
                if original?.endedAt == nil { activePlaySession = original }
                errorMessage = "수정 실패: \(error.localizedDescription)"
            }
        }
    }

    /// 편집 시트에서 배변 빠른 추가(웹 handleAddDiaper 재현). 시각 지정 별도 기록.
    func addDiaper(type: DiaperType, at date: Date) async {
        let diaper = DiaperRecord.new(babyId: babyId, diaperType: type, recordedAt: date)
        await insertDiaper(diaper)
    }

    // MARK: - 삭제

    func delete(_ item: TimelineItem, on day: Date) {
        let key = Calendar.kst.startOfDay(for: day)
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
        case .checkup:
            break   // 검진은 달력 전용 — 타임라인 삭제 없음
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

// MARK: - EditableRecord (편집 시트 입력 — 도메인 원본 래핑)

/// RecordEditSheet 에 넘길 편집 대상. 각 케이스가 현재 필드값을 그대로 보유.
enum EditableRecord: Identifiable {
    case feeding(Feeding)
    case sleep(SleepRecord)
    case diaper(DiaperRecord)
    case play(PlayRecord)

    var id: UUID {
        switch self {
        case .feeding(let f): return f.id
        case .sleep(let s):   return s.id
        case .diaper(let d):  return d.id
        case .play(let p):    return p.id
        }
    }
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
        // 양·질감(있는 것만, 양→질감 순) 병기. 예: "소변 (보통)", "대변 (많이·찰흙)".
        var parts: [String] = []
        if let amount { parts.append(amount.displayName) }
        if diaperType.hasPoo, let state = stoolState { parts.append(state.textureShortLabel) }
        if !parts.isEmpty { label += " (\(parts.joined(separator: "·")))" }
        if diaperType.hasPoo, let color = stoolColor { label += " · \(color.diaperColorLabel)" }
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
        // 즉시 기록(기간 없음) → 이름만(분유처럼 시점만 표기). 기간 있으면 legacy로 "(N분)".
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
