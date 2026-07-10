// Domain/Repositories/DevelopmentRepository.swift
// 발달 콘텐츠 조회(읽기 전용) — Foundation only.

import Foundation

protocol DevelopmentRepository {
    /// 생후 일수 기준 현재 시기 + 이전/다음.
    func currentStage(ageDays: Int) async throws -> DevelopmentStageBundle
    /// 전체 마일스톤 (정적).
    func milestones() async throws -> [Milestone]
}
