// Feature/Feeding/FeedingViewModel.swift

import Foundation
import Observation

@Observable
final class FeedingViewModel {
    // MARK: - Published State
    var feedings: [Feeding] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // Input Sheet State
    var selectedType: FeedingType = .formula
    var amountMlText: String = ""
    var durationText: String = ""
    var memo: String = ""
    var startedAt: Date = .now

    // Undo
    var lastSavedId: UUID? = nil
    var showUndoSnackbar: Bool = false

    // MARK: - Dependencies (Domain 프로토콜만 의존)
    private let repository: FeedingRepository
    private let saveUseCase: SaveFeedingUseCase
    private let babyId: UUID

    init(repository: FeedingRepository, babyId: UUID) {
        self.repository = repository
        self.saveUseCase = SaveFeedingUseCase(repository: repository)
        self.babyId = babyId
    }

    // MARK: - Actions

    func loadFeedings(for date: Date = .now) {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                feedings = try await repository.list(babyId: babyId, on: date)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveFeeding() {
        let amountMl = Int(amountMlText)
        let duration = Int(durationText)

        let optimisticFeeding = Feeding.new(
            babyId: babyId,
            type: selectedType,
            amountMl: selectedType == .formula ? amountMl : nil,
            durationMinutes: selectedType.isBreast ? duration : nil,
            startedAt: startedAt,
            memo: memo.isEmpty ? nil : memo
        )

        // (1) 낙관적 즉시 삽입
        feedings.insert(optimisticFeeding, at: 0)
        lastSavedId = optimisticFeeding.id
        showUndoSnackbar = true
        resetInputs()

        Task { @MainActor in
            do {
                // (2) 서버 POST
                let confirmed = try await saveUseCase.execute(optimisticFeeding)
                // (3) 낙관적 항목 → 서버 확정 항목으로 교체
                if let idx = feedings.firstIndex(where: { $0.id == optimisticFeeding.id }) {
                    feedings[idx] = confirmed
                }
                lastSavedId = confirmed.id
            } catch {
                // (4) 실패 → 롤백
                feedings.removeAll { $0.id == optimisticFeeding.id }
                lastSavedId = nil
                showUndoSnackbar = false
                errorMessage = "저장 실패: \(error.localizedDescription)"
            }
        }
    }

    func undoLastSave() {
        guard let id = lastSavedId else { return }
        // 낙관적 제거
        let backup = feedings.first { $0.id == id }
        feedings.removeAll { $0.id == id }
        lastSavedId = nil
        showUndoSnackbar = false

        guard let toDelete = backup else { return }
        Task { @MainActor in
            do {
                try await repository.delete(id: id, babyId: toDelete.babyId)
            } catch {
                // 실패 시 복원
                if let backup = backup {
                    feedings.insert(backup, at: 0)
                }
                errorMessage = "취소 실패: \(error.localizedDescription)"
            }
        }
    }

    func deleteFeeding(_ feeding: Feeding) {
        // 낙관적 제거
        feedings.removeAll { $0.id == feeding.id }
        Task { @MainActor in
            do {
                try await repository.delete(id: feeding.id, babyId: feeding.babyId)
            } catch {
                // 실패 시 복원
                feedings.insert(feeding, at: 0)
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Computed

    var isFormValid: Bool {
        if selectedType == .formula {
            return Int(amountMlText) != nil
        }
        return true
    }

    // MARK: - Private

    private func resetInputs() {
        amountMlText = ""
        durationText = ""
        memo = ""
        startedAt = .now
    }
}
