// Feature/Settings/BabyProfileViewModel.swift
// 아기 프로필 편집 VM — 이름/생년월일·시각/성별/출생 측정치/혈액형/사진URL.
// BabyRepository.update(PATCH /babies/{id}). 낙관적 갱신은 상위(Settings)로 콜백 전달.

import Foundation
import Observation

@Observable
final class BabyProfileViewModel {

    // MARK: - Editable Fields

    var name: String
    var birthDate: Date              // 날짜 + 시각 모두 보유(단일 DatePicker).
    var gender: Gender
    var photoUrlText: String
    var birthWeightKgText: String    // UI 입력: kg 단위(온보딩과 동일). 저장 시 g로 변환.
    var birthHeightCmText: String    // cm(Double 그대로 저장)
    var birthHeadCircumferenceCmText: String
    var birthChestCircumferenceCmText: String
    var bloodType: BloodType?        // 미선택 허용
    var rhFactor: RhFactor?          // 미선택 허용

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
        self.bloodType = baby.bloodType
        self.rhFactor = baby.rhFactor
        // g → kg 텍스트("3.2"). 없으면 빈 값.
        if let g = baby.birthWeightG, g > 0 {
            let kg = Double(g) / 1000.0
            self.birthWeightKgText = Self.trimNumber(kg)
        } else {
            self.birthWeightKgText = ""
        }
        self.birthHeightCmText = baby.birthHeightCm.map(Self.trimNumber) ?? ""
        self.birthHeadCircumferenceCmText = baby.birthHeadCircumferenceCm.map(Self.trimNumber) ?? ""
        self.birthChestCircumferenceCmText = baby.birthChestCircumferenceCm.map(Self.trimNumber) ?? ""
    }

    /// 소수 불필요한 0 제거(3.20 → 3.2, 3.0 → 3).
    private static func trimNumber(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(v)
    }

    // MARK: - Validation

    var isFormValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return birthWeightValidation == nil
            && birthHeightValidation == nil
            && birthHeadValidation == nil
            && birthChestValidation == nil
    }

    /// 출생 체중 입력 검증(0~15 kg). 정상/빈 값이면 nil.
    var birthWeightValidation: String? {
        Self.validate(birthWeightKgText, range: 0...15, unit: "kg", example: "3.2")
    }

    /// 출생 키 검증(0~120 cm).
    var birthHeightValidation: String? {
        Self.validate(birthHeightCmText, range: 0...120, unit: "cm", example: "50")
    }

    /// 두위 검증(0~80 cm).
    var birthHeadValidation: String? {
        Self.validate(birthHeadCircumferenceCmText, range: 0...80, unit: "cm", example: "34")
    }

    /// 흉위 검증(0~80 cm).
    var birthChestValidation: String? {
        Self.validate(birthChestCircumferenceCmText, range: 0...80, unit: "cm", example: "33")
    }

    /// 공통 숫자 범위 검증. 빈 값이면 nil(선택 입력).
    private static func validate(
        _ text: String, range: ClosedRange<Double>, unit: String, example: String
    ) -> String? {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        guard let v = Double(t) else { return "숫자로 입력해 주세요 (예: \(example))" }
        guard range.contains(v) else {
            return "\(Self.trimNumber(range.lowerBound))~\(Self.trimNumber(range.upperBound)) \(unit) 범위로 입력해 주세요."
        }
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
                // kg 텍스트 → g(정수). 빈 값이면 nil.
                let trimmedKg = birthWeightKgText.trimmingCharacters(in: .whitespaces)
                updated.birthWeightG = trimmedKg.isEmpty ? nil : Double(trimmedKg).map { Int($0 * 1000) }
                // cm(Double 그대로). 빈 값이면 nil.
                updated.birthHeightCm = Self.parseCm(birthHeightCmText)
                updated.birthHeadCircumferenceCm = Self.parseCm(birthHeadCircumferenceCmText)
                updated.birthChestCircumferenceCm = Self.parseCm(birthChestCircumferenceCmText)
                updated.bloodType = bloodType
                updated.rhFactor = rhFactor

                let saved = try await babyRepository.update(updated)
                onSaved?(saved)
                didSave = true
            } catch {
                errorMessage = "저장에 실패했어요. 다시 시도해 주세요."
            }
        }
    }

    private static func parseCm(_ text: String) -> Double? {
        let t = text.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : Double(t)
    }
}
