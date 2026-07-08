// Domain/Repositories/BabyRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol BabyRepository {
    func create(_ baby: Baby) throws
    func update(_ baby: Baby) throws
    func softDelete(id: UUID) throws
    func fetch(id: UUID) throws -> Baby?
    func fetchAll() throws -> [Baby]
    func activeBaby() throws -> Baby?

    // 동기화 훅 (MVP 미호출)
    func pendingSync() throws -> [Baby]
    func markSynced(ids: [UUID], serverTime: Date) throws
    func applyRemote(_ remote: [Baby]) throws
}
