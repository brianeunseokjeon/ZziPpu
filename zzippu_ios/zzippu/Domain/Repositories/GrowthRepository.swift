// Domain/Repositories/GrowthRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol GrowthRepository {
    func create(_ record: GrowthRecord) async throws -> GrowthRecord
    func update(_ record: GrowthRecord) async throws -> GrowthRecord
    func delete(id: UUID, babyId: UUID) async throws
    func series(babyId: UUID) async throws -> [GrowthRecord]
}
