// Domain/UseCases/SavePlayUseCase.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

final class SavePlayUseCase {
    private let repository: PlayRepository

    init(repository: PlayRepository) {
        self.repository = repository
    }

    @discardableResult
    func execute(_ play: PlayRecord) async throws -> PlayRecord {
        if let min = play.durationMinutes, min <= 0 {
            throw DomainError.invalidInput("놀이 시간은 0분 이상이어야 합니다.")
        }
        return try await repository.create(play)
    }
}
