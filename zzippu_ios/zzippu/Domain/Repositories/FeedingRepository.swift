// Domain/Repositories/FeedingRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol FeedingRepository {
    // --- 로컬 CRUD ---
    func create(_ feeding: Feeding) throws
    func update(_ feeding: Feeding) throws
    func softDelete(id: UUID) throws
    func fetch(id: UUID) throws -> Feeding?
    func list(babyId: UUID, on day: Date) throws -> [Feeding]
    func lastFeeding(babyId: UUID) throws -> Feeding?

    // --- 미래 동기화 훅 (MVP에선 미호출, 구현만 존재) ---
    func pendingSync(babyId: UUID) throws -> [Feeding]
    func markSynced(ids: [UUID], serverTime: Date) throws
    func applyRemote(_ remote: [Feeding]) throws
}
