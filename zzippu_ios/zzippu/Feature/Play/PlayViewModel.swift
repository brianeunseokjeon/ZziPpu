// Feature/Play/PlayViewModel.swift

import Foundation
import Observation

@Observable
final class PlayViewModel {
    // MARK: - Published State
    var plays: [PlayRecord] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // Input Sheet State
    var selectedType: PlayType = .tummyTime
    var durationMinutes: Int = 10
    var startedAt: Date = .now

    // MARK: - Dependencies
    private let repository: PlayRepository
    private let saveUseCase: SavePlayUseCase
    let babyId: UUID

    init(repository: PlayRepository, babyId: UUID) {
        self.repository = repository
        self.saveUseCase = SavePlayUseCase(repository: repository)
        self.babyId = babyId
    }

    // MARK: - Actions

    func loadPlays(for date: Date = .now) {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                plays = try await repository.list(babyId: babyId, on: date)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func savePlay() {
        let endedAt = startedAt.addingTimeInterval(Double(durationMinutes) * 60)
        let optimistic = PlayRecord.new(
            babyId: babyId,
            playType: selectedType,
            startedAt: startedAt,
            endedAt: endedAt,
            durationMinutes: durationMinutes > 0 ? durationMinutes : nil
        )
        plays.insert(optimistic, at: 0)
        resetInputs()

        Task { @MainActor in
            do {
                let confirmed = try await saveUseCase.execute(optimistic)
                if let idx = plays.firstIndex(where: { $0.id == optimistic.id }) {
                    plays[idx] = confirmed
                }
            } catch {
                plays.removeAll { $0.id == optimistic.id }
                errorMessage = "저장 실패: \(error.localizedDescription)"
            }
        }
    }

    func deletePlay(_ play: PlayRecord) {
        plays.removeAll { $0.id == play.id }
        Task { @MainActor in
            do {
                try await repository.delete(id: play.id, babyId: play.babyId)
            } catch {
                plays.insert(play, at: 0)
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Private

    func resetInputs() {
        selectedType = .tummyTime
        durationMinutes = 10
        startedAt = .now
    }
}
