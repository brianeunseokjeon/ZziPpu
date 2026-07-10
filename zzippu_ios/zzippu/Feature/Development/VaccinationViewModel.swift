// Feature/Development/VaccinationViewModel.swift
// 예방접종 ViewModel — 목록 조회 + 완료 처리.
// isOverdue/daysUntil는 Vaccination 엔티티의 로컬 computed 사용.

import Foundation
import Observation

@Observable
final class VaccinationViewModel {

    // MARK: - State

    var vaccinations: [Vaccination] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // 완료 처리 시트
    var editingVaccination: Vaccination?
    var isSubmitting: Bool = false

    // MARK: - Dependencies

    private let repository: VaccinationRepository
    private let babyId: UUID

    // MARK: - Init

    init(repository: VaccinationRepository, babyId: UUID) {
        self.repository = repository
        self.babyId = babyId
    }

    // MARK: - Derived (권장일 기준 정렬: 미완료 먼저, 그다음 예정일순)

    var sortedVaccinations: [Vaccination] {
        vaccinations.sorted { lhs, rhs in
            if lhs.isAdministered != rhs.isAdministered {
                return !lhs.isAdministered   // 미완료를 위로
            }
            return lhs.scheduledDate < rhs.scheduledDate
        }
    }

    // MARK: - Actions

    func load() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                vaccinations = try await repository.list(babyId: babyId)
                errorMessage = nil
            } catch {
                errorMessage = "접종 정보를 불러오지 못했어요"
            }
        }
    }

    func beginEditing(_ vaccination: Vaccination) {
        editingVaccination = vaccination
    }

    func markAdministered(
        id: UUID,
        administeredDate: Date,
        hospitalName: String?
    ) {
        isSubmitting = true
        Task { @MainActor in
            defer { isSubmitting = false }
            do {
                let updated = try await repository.markAdministered(
                    babyId: babyId,
                    id: id,
                    administeredDate: administeredDate,
                    hospitalName: hospitalName
                )
                if let idx = vaccinations.firstIndex(where: { $0.id == updated.id }) {
                    vaccinations[idx] = updated
                }
                editingVaccination = nil
                errorMessage = nil
            } catch {
                errorMessage = "완료 처리에 실패했어요"
            }
        }
    }
}
