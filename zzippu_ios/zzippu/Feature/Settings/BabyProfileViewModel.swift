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
    var birthWeightKgText: String   // UI 입력: kg 단위(온보딩과 동일). 저장 시 g로 변환.

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
        // g → kg 텍스트("3.2"). 없으면 빈 값.
        if let g = baby.birthWeightG, g > 0 {
            let kg = Double(g) / 1000.0
            // 소수 불필요한 0 제거(3.20 → 3.2, 3.0 → 3).
            self.birthWeightKgText = kg == kg.rounded() ? String(Int(kg)) : String(kg)
        } else {
            self.birthWeightKgText = ""
        }
    }

    // MARK: - Validation

    var isFormValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return birthWeightValidation == nil   // 체중 형식 오류 시 저장 차단
    }

    /// 출생 체중 입력 검증(온보딩과 동일 규칙: 0~15 kg). 정상/빈 값이면 nil.
    var birthWeightValidation: String? {
        let text = birthWeightKgText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }          // 선택 입력 — 비어도 OK
        guard let kg = Double(text) else { return "숫자로 입력해 주세요 (예: 3.2)" }
        guard (0...15).contains(kg) else { return "0~15 kg 범위로 입력해 주세요." }
        return nil
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
                // kg 텍스트 → g(정수). 빈 값이면 nil(미입력). 검증은 isFormValid에서 선통과.
                let trimmedKg = birthWeightKgText.trimmingCharacters(in: .whitespaces)
                updated.birthWeightG = trimmedKg.isEmpty ? nil : Double(trimmedKg).map { Int($0 * 1000) }

                let saved = try await babyRepository.update(updated)
                onSaved?(saved)
                didSave = true
            } catch {
                errorMessage = "저장에 실패했어요. 다시 시도해 주세요."
            }
        }
    }
}
