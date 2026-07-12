// Feature/Diaper/DiaperViewModel.swift

import Foundation
import Observation

@Observable
final class DiaperViewModel {
    // MARK: - Published State
    var diapers: [DiaperRecord] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // Input Sheet State
    var selectedType: DiaperType = .pee
    var selectedColor: StoolColor? = nil
    var selectedState: StoolState? = nil   // 대변 질감(묽음/보통/찰흙 = watery/normal/hard)
    var selectedAmount: DiaperAmount? = nil // 양(소변·대변 공통)
    var recordedAt: Date = .now
    var memo: String = ""

    // MARK: - Dependencies
    private let repository: DiaperRepository
    private let saveUseCase: SaveDiaperUseCase
    let babyId: UUID

    init(repository: DiaperRepository, babyId: UUID) {
        self.repository = repository
        self.saveUseCase = SaveDiaperUseCase(repository: repository)
        self.babyId = babyId
    }

    // MARK: - Actions

    func loadDiapers(for date: Date = .now) {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                diapers = try await repository.list(babyId: babyId, on: date)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveDiaper() {
        let optimistic = DiaperRecord.new(
            babyId: babyId,
            diaperType: selectedType,
            recordedAt: recordedAt,
            stoolColor: selectedType.hasPoo ? selectedColor : nil,
            stoolState: selectedType.hasPoo ? selectedState : nil,
            amount: selectedAmount,
            memo: memo.isEmpty ? nil : memo
        )
        diapers.insert(optimistic, at: 0)
        resetInputs()

        Task { @MainActor in
            do {
                let confirmed = try await saveUseCase.execute(optimistic)
                if let idx = diapers.firstIndex(where: { $0.id == optimistic.id }) {
                    diapers[idx] = confirmed
                }
            } catch {
                diapers.removeAll { $0.id == optimistic.id }
                errorMessage = "저장 실패: \(error.localizedDescription)"
            }
        }
    }

    func deleteDiaper(_ diaper: DiaperRecord) {
        diapers.removeAll { $0.id == diaper.id }
        Task { @MainActor in
            do {
                try await repository.delete(id: diaper.id, babyId: diaper.babyId)
            } catch {
                diapers.insert(diaper, at: 0)
                errorMessage = "삭제 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Private

    func resetInputs() {
        selectedType = .pee
        selectedColor = nil
        selectedState = nil
        selectedAmount = nil
        recordedAt = .now
        memo = ""
    }
}
