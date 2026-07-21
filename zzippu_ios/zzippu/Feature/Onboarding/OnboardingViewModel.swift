// Feature/Onboarding/OnboardingViewModel.swift
// BabyRepository + GrowthRepository 프로토콜만 의존

import Foundation
import Observation

@Observable
final class OnboardingViewModel {

    // MARK: - Input State
    var babyName: String = ""
    var birthDate: Date = Calendar.kst.date(
        byAdding: .day, value: -1,
        to: Calendar.kst.startOfDay(for: .now)
    ) ?? .now
    var gender: Gender = .unknown
    var birthWeightKgText: String = ""   // UI 입력: kg 단위 (0~15)
    var birthHeightCmText: String = ""   // UI 입력: cm 단위 (0~120)

    // MARK: - Status
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Dependencies
    private let babyRepository: BabyRepository
    private let growthRepository: GrowthRepository
    private let userId: UUID?

    /// 완료 콜백 — 서버에서 받은 Baby 엔티티를 전달 (activeBabyId 설정용)
    var onCompleted: ((Baby) -> Void)?

    init(babyRepository: BabyRepository,
         growthRepository: GrowthRepository,
         userId: UUID? = nil) {
        self.babyRepository = babyRepository
        self.growthRepository = growthRepository
        self.userId = userId
    }

    // MARK: - Actions

    func save() {
        guard isFormValid else {
            errorMessage = "아이 이름을 입력해 주세요."
            return
        }
        isLoading = true

        Task { @MainActor in
            defer { isLoading = false }
            do {
                // 출생체중 변환 (kg → g, 0~15 kg 검증)
                var birthWeightG: Int? = nil
                if !birthWeightKgText.isEmpty,
                   let kg = Double(birthWeightKgText),
                   (0...15).contains(kg) {
                    birthWeightG = Int(kg * 1000)
                }

                // 출생 키 (cm, 0~120 검증)
                var birthHeightCm: Double? = nil
                if !birthHeightCmText.isEmpty,
                   let cm = Double(birthHeightCmText),
                   (0...120).contains(cm) {
                    birthHeightCm = cm
                }

                // Baby 생성 — 서버 POST, 반환값이 확정 엔티티
                let babyDraft = Baby.new(
                    userId: userId,
                    name: babyName.trimmingCharacters(in: .whitespaces),
                    birthDate: birthDate,
                    gender: gender,
                    birthWeightG: birthWeightG,
                    birthHeightCm: birthHeightCm
                )
                let savedBaby = try await babyRepository.create(babyDraft)

                // 출생체중·키 있으면 GrowthRecord 1건 자동 생성 (recordedAt = birthDate)
                if birthWeightG != nil || birthHeightCm != nil {
                    let growth = GrowthRecord.new(
                        babyId: savedBaby.id,
                        recordedAt: savedBaby.birthDate,
                        weightG: birthWeightG,
                        heightCm: birthHeightCm
                    )
                    _ = try await growthRepository.create(growth)
                }

                onCompleted?(savedBaby)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Computed

    var isFormValid: Bool {
        !babyName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var birthWeightValidation: String? {
        guard !birthWeightKgText.isEmpty else { return nil }
        guard let kg = Double(birthWeightKgText) else {
            return "숫자를 입력해 주세요."
        }
        guard (0...15).contains(kg) else {
            return "0~15 kg 범위로 입력해 주세요."
        }
        return nil
    }

    var birthHeightValidation: String? {
        guard !birthHeightCmText.isEmpty else { return nil }
        guard let cm = Double(birthHeightCmText) else {
            return "숫자를 입력해 주세요."
        }
        guard (0...120).contains(cm) else {
            return "0~120 cm 범위로 입력해 주세요."
        }
        return nil
    }
}
