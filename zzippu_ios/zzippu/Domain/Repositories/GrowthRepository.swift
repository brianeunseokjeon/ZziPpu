// Domain/Repositories/GrowthRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol GrowthRepository {
    func create(_ record: GrowthRecord) throws
    func update(_ record: GrowthRecord) throws
    func softDelete(id: UUID) throws
    func fetch(id: UUID) throws -> GrowthRecord?
    func series(babyId: UUID) throws -> [GrowthRecord]

    // 동기화 훅 (MVP 미호출)
    func pendingSync(babyId: UUID) throws -> [GrowthRecord]
    func markSynced(ids: [UUID], serverTime: Date) throws
    func applyRemote(_ remote: [GrowthRecord]) throws
}
