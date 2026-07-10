// Domain/Repositories/DiaperRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol DiaperRepository {
    func create(_ diaper: DiaperRecord) async throws -> DiaperRecord
    func delete(id: UUID, babyId: UUID) async throws
    func list(babyId: UUID, on day: Date) async throws -> [DiaperRecord]
}
