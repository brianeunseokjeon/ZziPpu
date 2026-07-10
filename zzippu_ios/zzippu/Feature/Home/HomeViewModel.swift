// Feature/Home/HomeViewModel.swift
// 홈 기록허브 ViewModel — activeBaby + 수유/수면/기저귀/놀이 통합 타임라인.
// Domain 프로토콜만 의존(클린아키텍처).

import Foundation
import Observation

@Observable
final class HomeViewModel {

    // MARK: - State

    var activeBaby: Baby?
    var selectedDate: Date = .now
    var isLoadingBaby: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    // 4개 도메인 목록
    var feedings: [Feeding] = []
    var sleeps: [SleepRecord] = []
    var diapers: [DiaperRecord] = []
    var plays: [PlayRecord] = []

    // 진행중 수면 세션
    var activeSleepSession: SleepRecord? = nil

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

    // MARK: - Actions

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

    /// 선택 날짜 4종 목록 + 진행중 수면 로드 (병렬)
    func loadAll(for date: Date? = nil) {
        let target = date ?? selectedDate
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                async let f = feedingRepository.list(babyId: babyId, on: target)
                async let s = sleepRepository.list(babyId: babyId, on: target)
                async let d = diaperRepository.list(babyId: babyId, on: target)
                async let p = playRepository.list(babyId: babyId, on: target)
                async let active = sleepRepository.activeSession(babyId: babyId)
                feedings = try await f
                sleeps   = try await s
                diapers  = try await d
                plays    = try await p
                activeSleepSession = try await active
            } catch {
                errorMessage = "기록 로드 실패: \(error.localizedDescription)"
            }
        }
    }

    // 하위호환 (기존 loadFeedings 호출부)
    func loadFeedings(for date: Date? = nil) {
        loadAll(for: date)
    }

    func changeDate(_ date: Date) {
        selectedDate = date
        loadAll(for: date)
    }

    // MARK: - Feeding CRUD

    func saveFeeding(_ feeding: Feeding) async {
        feedings.insert(feeding, at: 0)
        do {
            let confirmed = try await feedingRepository.create(feeding)
            await MainActor.run {
                if let idx = feedings.firstIndex(where: { $0.id == feeding.id }) {
                    feedings[idx] = confirmed
                }
            }
        } catch {
            await MainActor.run {
                feedings.removeAll { $0.id == feeding.id }
                errorMessage = "수유 저장 실패: \(error.localizedDescription)"
            }
        }
    }

    func deleteFeeding(_ feeding: Feeding) {
        feedings.removeAll { $0.id == feeding.id }
        Task { @MainActor in
            do {
                try await feedingRepository.delete(id: feeding.id, babyId: feeding.babyId)
            } catch {
                feedings.insert(feeding, at: 0)
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Sleep CRUD

    func saveSleep(_ sleep: SleepRecord) async {
        sleeps.insert(sleep, at: 0)
        activeSleepSession = sleep  // 낙관적 — 진행중으로 표시
        do {
            let confirmed = try await sleepRepository.create(sleep)
            await MainActor.run {
                if let idx = sleeps.firstIndex(where: { $0.id == sleep.id }) {
                    sleeps[idx] = confirmed
                }
                activeSleepSession = confirmed
            }
        } catch {
            await MainActor.run {
                sleeps.removeAll { $0.id == sleep.id }
                activeSleepSession = nil
                errorMessage = "수면 저장 실패: \(error.localizedDescription)"
            }
        }
    }

    /// 진행중 수면 종료
    func endActiveSleep() {
        guard let active = activeSleepSession else { return }
        let now = Date.now
        var ended = active
        ended.endedAt = now
        // 낙관적 업데이트
        if let idx = sleeps.firstIndex(where: { $0.id == active.id }) {
            sleeps[idx] = ended
        }
        activeSleepSession = nil

        Task { @MainActor in
            do {
                let confirmed = try await sleepRepository.endSleep(
                    id: active.id,
                    babyId: active.babyId,
                    endedAt: now
                )
                if let idx = sleeps.firstIndex(where: { $0.id == confirmed.id }) {
                    sleeps[idx] = confirmed
                }
            } catch {
                // 롤백
                if let idx = sleeps.firstIndex(where: { $0.id == active.id }) {
                    sleeps[idx] = active
                }
                activeSleepSession = active
                errorMessage = "수면 종료 실패: \(error.localizedDescription)"
            }
        }
    }

    func deleteSleep(_ sleep: SleepRecord) {
        sleeps.removeAll { $0.id == sleep.id }
        if activeSleepSession?.id == sleep.id { activeSleepSession = nil }
        Task { @MainActor in
            do {
                try await sleepRepository.delete(id: sleep.id, babyId: sleep.babyId)
            } catch {
                sleeps.insert(sleep, at: 0)
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Diaper CRUD

    func saveDiaper(_ diaper: DiaperRecord) async {
        diapers.insert(diaper, at: 0)
        do {
            let confirmed = try await diaperRepository.create(diaper)
            await MainActor.run {
                if let idx = diapers.firstIndex(where: { $0.id == diaper.id }) {
                    diapers[idx] = confirmed
                }
            }
        } catch {
            await MainActor.run {
                diapers.removeAll { $0.id == diaper.id }
                errorMessage = "기저귀 저장 실패: \(error.localizedDescription)"
            }
        }
    }

    func deleteDiaper(_ diaper: DiaperRecord) {
        diapers.removeAll { $0.id == diaper.id }
        Task { @MainActor in
            do {
                try await diaperRepository.delete(id: diaper.id, babyId: diaper.babyId)
            } catch {
                diapers.insert(diaper, at: 0)
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Play CRUD

    func savePlay(_ play: PlayRecord) async {
        plays.insert(play, at: 0)
        do {
            let confirmed = try await playRepository.create(play)
            await MainActor.run {
                if let idx = plays.firstIndex(where: { $0.id == play.id }) {
                    plays[idx] = confirmed
                }
            }
        } catch {
            await MainActor.run {
                plays.removeAll { $0.id == play.id }
                errorMessage = "놀이 저장 실패: \(error.localizedDescription)"
            }
        }
    }

    func deletePlay(_ play: PlayRecord) {
        plays.removeAll { $0.id == play.id }
        Task { @MainActor in
            do {
                try await playRepository.delete(id: play.id, babyId: play.babyId)
            } catch {
                plays.insert(play, at: 0)
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Computed — 통합 타임라인

    var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []
        items += feedings.map { TimelineItem(from: $0) }
        items += sleeps.map   { TimelineItem(from: $0) }
        items += diapers.map  { TimelineItem(from: $0) }
        items += plays.map    { TimelineItem(from: $0) }
        return items.sorted { $0.time > $1.time }
    }

    // 하위호환 (기존 feedingGroups 참조 방어)
    var feedingGroups: [FeedingTimelineGroup] {
        FeedingTimelineGroup.grouped(from: feedings)
    }
}

// MARK: - TimelineItem (통합 타임라인 행)

struct TimelineItem: Identifiable {
    let id: UUID
    let time: Date
    let label: String
    let domainKind: DomainKind
    // 삭제 액션용 payload
    let onDelete: (() -> Void)?

    // MARK: - Factory

    init(from feeding: Feeding) {
        self.id = feeding.id
        self.time = feeding.startedAt
        self.label = feeding.timelineLabel
        self.domainKind = feeding.domainKind
        self.onDelete = nil  // HomeView에서 주입
    }

    init(from sleep: SleepRecord) {
        self.id = sleep.id
        self.time = sleep.startedAt
        self.label = sleep.timelineLabel
        self.domainKind = .sleep
        self.onDelete = nil
    }

    init(from diaper: DiaperRecord) {
        self.id = diaper.id
        self.time = diaper.recordedAt
        self.label = diaper.timelineLabel
        self.domainKind = diaper.domainKind
        self.onDelete = nil
    }

    init(from play: PlayRecord) {
        self.id = play.id
        self.time = play.startedAt
        self.label = play.timelineLabel
        self.domainKind = .play
        self.onDelete = nil
    }
}

// MARK: - FeedingTimelineGroup (하위호환 유지)

struct FeedingTimelineGroup: Identifiable {
    let id: UUID = UUID()
    let minuteKey: Date
    let items: [Feeding]
    var isLatest: Bool = false

    static func grouped(from feedings: [Feeding]) -> [FeedingTimelineGroup] {
        guard !feedings.isEmpty else { return [] }
        let cal = Calendar.current
        let sorted = feedings.sorted { $0.startedAt > $1.startedAt }
        var buckets: [Date: [Feeding]] = [:]
        for f in sorted {
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: f.startedAt)
            let key = cal.date(from: comps) ?? f.startedAt
            buckets[key, default: []].append(f)
        }
        var groups = buckets.map { FeedingTimelineGroup(minuteKey: $0.key, items: $0.value) }
            .sorted { $0.minuteKey > $1.minuteKey }
        if !groups.isEmpty { groups[0].isLatest = true }
        return groups
    }
}

// MARK: - Domain Label Helpers (Feature 레이어)

extension Feeding {
    var timelineLabel: String {
        switch type {
        case .formula:
            return amountMl.map { "분유 \($0)ml" } ?? "분유"
        case .breastLeft:
            return durationMinutes.map { "모유(좌) \($0)분" } ?? "모유(좌)"
        case .breastRight:
            return durationMinutes.map { "모유(우) \($0)분" } ?? "모유(우)"
        case .breastBoth:
            return durationMinutes.map { "모유(양쪽) \($0)분" } ?? "모유(양쪽)"
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
        if isActive {
            return "수면 중 · \(elapsedMinutes())분 경과"
        }
        if let min = durationMinutes {
            let h = min / 60
            let m = min % 60
            if h > 0 { return "수면 \(h)시간 \(m > 0 ? "\(m)분" : "")" }
            return "수면 \(m)분"
        }
        return "수면"
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
        if let min = durationMinutes {
            return "\(playType.displayName) \(min)분"
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
        return AppHeaderBaby(
            name:      name,
            birthDate: birthDate,
            gender:    gender,
            photoURL:  photoURL
        )
    }
}
