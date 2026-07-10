// Feature/Sleep/SleepViewModel.swift

import Foundation
import Observation

@Observable
final class SleepViewModel {
    // MARK: - Published State
    var sleeps: [SleepRecord] = []
    var activeSession: SleepRecord? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // Input Sheet State
    var startedAt: Date = .now
    var memo: String = ""

    // MARK: - Dependencies
    private let repository: SleepRepository
    private let saveUseCase: SaveSleepUseCase
    let babyId: UUID

    init(repository: SleepRepository, babyId: UUID) {
        self.repository = repository
        self.saveUseCase = SaveSleepUseCase(repository: repository)
        self.babyId = babyId
    }

    // MARK: - Actions

    func loadSleeps(for date: Date = .now) {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                sleeps = try await repository.list(babyId: babyId, on: date)
                activeSession = try await repository.activeSession(babyId: babyId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func startSleep() {
        let optimistic = SleepRecord.new(
            babyId: babyId,
            startedAt: startedAt,
            memo: memo.isEmpty ? nil : memo
        )
        sleeps.insert(optimistic, at: 0)
        activeSession = optimistic
        resetInputs()

        Task { @MainActor in
            do {
                let confirmed = try await saveUseCase.execute(optimistic)
                if let idx = sleeps.firstIndex(where: { $0.id == optimistic.id }) {
                    sleeps[idx] = confirmed
                }
                activeSession = confirmed
            } catch {
                sleeps.removeAll { $0.id == optimistic.id }
                activeSession = nil
                errorMessage = "수면 시작 실패: \(error.localizedDescription)"
            }
        }
    }

    func endSleep(_ sleep: SleepRecord) {
        let now = Date.now
        var ended = sleep
        ended.endedAt = now
        // 낙관적 업데이트
        if let idx = sleeps.firstIndex(where: { $0.id == sleep.id }) {
            sleeps[idx] = ended
        }
        activeSession = nil

        Task { @MainActor in
            do {
                let confirmed = try await saveUseCase.end(id: sleep.id, babyId: sleep.babyId, endedAt: now)
                if let idx = sleeps.firstIndex(where: { $0.id == confirmed.id }) {
                    sleeps[idx] = confirmed
                }
            } catch {
                // 롤백
                if let idx = sleeps.firstIndex(where: { $0.id == sleep.id }) {
                    sleeps[idx] = sleep
                }
                activeSession = sleep
                errorMessage = "수면 종료 실패: \(error.localizedDescription)"
            }
        }
    }

    func deleteSleep(_ sleep: SleepRecord) {
        sleeps.removeAll { $0.id == sleep.id }
        if activeSession?.id == sleep.id { activeSession = nil }
        Task { @MainActor in
            do {
                try await repository.delete(id: sleep.id, babyId: sleep.babyId)
            } catch {
                sleeps.insert(sleep, at: 0)
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Private

    func resetInputs() {
        startedAt = .now
        memo = ""
    }
}
