// Feature/Settings/BabyProfileViewModel.swift
// 아기 프로필 편집 VM — 이름/생년월일/성별/사진URL.
// BabyRepository.update(PATCH /babies/{id}). 낙관적 갱신은 상위(Settings)로 콜백 전달.

import Foundation
import Observation

@Observable
final class BabyProfileViewModel {

    // MARK: - Editable Fields

    var name: String
    var birthDate: Date
    var gender: Gender
    var photoUrlText: String

    // MARK: - Status

    var isSaving: Bool = false
    var errorMessage: String?
    var didSave: Bool = false

    // MARK: - Dependencies

    private let babyRepository: BabyRepository
    private let original: Baby

    /// 저장 성공 시 서버 확정 Baby 전달 (상위에서 낙관적 반영)
    var onSaved: ((Baby) -> Void)?

    init(baby: Baby, babyRepository: BabyRepository) {
        self.original = baby
        self.babyRepository = babyRepository
        self.name = baby.name
        self.birthDate = baby.birthDate
        self.gender = baby.gender
        self.photoUrlText = baby.photoUrl ?? ""
    }

    // MARK: - Validation

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    func save() {
        guard isFormValid else {
            errorMessage = "아이 이름을 입력해 주세요."
            return
        }
        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            do {
                var updated = original
                updated.name = name.trimmingCharacters(in: .whitespaces)
                updated.birthDate = birthDate
                updated.gender = gender
                let trimmedURL = photoUrlText.trimmingCharacters(in: .whitespaces)
                updated.photoUrl = trimmedURL.isEmpty ? nil : trimmedURL

                let saved = try await babyRepository.update(updated)
                onSaved?(saved)
                didSave = true
            } catch {
                errorMessage = "저장에 실패했어요. 다시 시도해 주세요."
            }
        }
    }
}
