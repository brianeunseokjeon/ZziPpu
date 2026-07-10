// Domain/UseCases/SaveSleepUseCase.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

final class SaveSleepUseCase {
    private let repository: SleepRepository

    init(repository: SleepRepository) {
        self.repository = repository
    }

    /// 수면 시작 기록 저장 (POST /sleeps → endedAt nil)
    @discardableResult
    func execute(_ sleep: SleepRecord) async throws -> SleepRecord {
        return try await repository.create(sleep)
    }

    /// 진행중 수면 종료 (PUT /{id}/end)
    @discardableResult
    func end(id: UUID, babyId: UUID, endedAt: Date = .now) async throws -> SleepRecord {
        return try await repository.endSleep(id: id, babyId: babyId, endedAt: endedAt)
    }
}
