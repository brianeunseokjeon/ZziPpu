// Domain/UseCases/SaveDiaperUseCase.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

final class SaveDiaperUseCase {
    private let repository: DiaperRepository

    init(repository: DiaperRepository) {
        self.repository = repository
    }

    @discardableResult
    func execute(_ diaper: DiaperRecord) async throws -> DiaperRecord {
        return try await repository.create(diaper)
    }
}
