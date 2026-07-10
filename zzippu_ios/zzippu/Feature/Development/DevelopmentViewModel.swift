// Feature/Development/DevelopmentViewModel.swift
// 발달 이정표 ViewModel — 현재 시기 + 마일스톤(읽기 전용).
// Domain 프로토콜만 의존.

import Foundation
import Observation

@Observable
final class DevelopmentViewModel {

    // MARK: - State

    var stageBundle: DevelopmentStageBundle?
    var milestones: [Milestone] = []
    var ageDays: Int = 0
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let developmentRepository: DevelopmentRepository
    private let babyRepository: BabyRepository
    private let babyId: UUID

    // MARK: - Init

    init(
        developmentRepository: DevelopmentRepository,
        babyRepository: BabyRepository,
        babyId: UUID
    ) {
        self.developmentRepository = developmentRepository
        self.babyRepository = babyRepository
        self.babyId = babyId
    }

    // MARK: - Derived

    var currentStage: DevelopmentStage? { stageBundle?.current }

    /// 마일스톤을 지난/현재/다가올로 분류하기 위한 상태.
    enum MilestoneStatus { case past, current, upcoming }

    func status(for milestone: Milestone) -> MilestoneStatus {
        // 현재 = 마일스톤 목표일 ± 7일 이내.
        let window = 7
        if ageDays >= milestone.days - window && ageDays <= milestone.days + window {
            return .current
        }
        return ageDays > milestone.days ? .past : .upcoming
    }

    // MARK: - Actions

    func load() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                let baby = try await babyRepository.fetch(id: babyId)
                let days = baby.map { Self.ageDays(birthDate: $0.birthDate) } ?? 1
                self.ageDays = days

                async let bundle = developmentRepository.currentStage(ageDays: days)
                async let stones = developmentRepository.milestones()
                self.stageBundle = try await bundle
                self.milestones = try await stones.sorted { $0.days < $1.days }
                self.errorMessage = nil
            } catch {
                self.errorMessage = "발달 정보를 불러오지 못했어요"
            }
        }
    }

    // MARK: - Helpers

    /// 한국식 생후 일수: 생일 당일 = 1.
    static func ageDays(birthDate: Date, now: Date = .now) -> Int {
        let cal = Calendar.current
        let birth = cal.startOfDay(for: birthDate)
        let today = cal.startOfDay(for: now)
        let diff = cal.dateComponents([.day], from: birth, to: today).day ?? 0
        return max(0, diff) + 1
    }
}
