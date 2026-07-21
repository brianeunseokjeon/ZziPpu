// Domain/Repositories/CareLogRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol CareLogRepository {
    func create(_ log: CareLog) async throws -> CareLog
    func update(_ log: CareLog) async throws -> CareLog
    func delete(id: UUID, babyId: UUID) async throws
    func list(babyId: UUID, on day: Date) async throws -> [CareLog]
}
