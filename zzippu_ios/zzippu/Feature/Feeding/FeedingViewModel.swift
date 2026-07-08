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
        do {
            feedings = try repository.list(babyId: babyId, on: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveFeeding() {
        let amountMl = Int(amountMlText)
        let duration = Int(durationText)

        let feeding = Feeding.new(
            babyId: babyId,
            type: selectedType,
            amountMl: selectedType == .formula ? amountMl : nil,
            durationMinutes: selectedType.isBreast ? duration : nil,
            startedAt: startedAt,
            memo: memo.isEmpty ? nil : memo
        )

        do {
            try saveUseCase.execute(feeding)
            lastSavedId = feeding.id
            showUndoSnackbar = true
            loadFeedings(for: startedAt)
            resetInputs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoLastSave() {
        guard let id = lastSavedId else { return }
        do {
            try repository.softDelete(id: id)
            lastSavedId = nil
            showUndoSnackbar = false
            loadFeedings()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteFeeding(id: UUID) {
        do {
            try repository.softDelete(id: id)
            loadFeedings()
        } catch {
            errorMessage = error.localizedDescription
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
