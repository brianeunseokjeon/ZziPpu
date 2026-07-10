// Domain/Repositories/PlayRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol PlayRepository {
    func create(_ play: PlayRecord) async throws -> PlayRecord
    func delete(id: UUID, babyId: UUID) async throws
    func list(babyId: UUID, on day: Date) async throws -> [PlayRecord]
}
