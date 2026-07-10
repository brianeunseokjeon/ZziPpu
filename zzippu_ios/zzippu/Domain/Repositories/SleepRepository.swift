// Domain/Repositories/SleepRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol SleepRepository {
    func create(_ sleep: SleepRecord) async throws -> SleepRecord
    func endSleep(id: UUID, babyId: UUID, endedAt: Date) async throws -> SleepRecord
    func delete(id: UUID, babyId: UUID) async throws
    func list(babyId: UUID, on day: Date) async throws -> [SleepRecord]
    func activeSession(babyId: UUID) async throws -> SleepRecord?
}
