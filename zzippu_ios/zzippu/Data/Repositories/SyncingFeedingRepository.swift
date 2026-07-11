// Data/Repositories/SyncingFeedingRepository.swift
// LocalFeedingRepository 데코레이터 — 로컬 쓰기 후 SyncEngine 에 로컬-변경 트리거(디바운스 push).
// FeedingRepository 프로토콜 무변경. Feature 는 이 데코레이터를 Local과 구분하지 못한다.
// 읽기는 그대로 위임, 쓰기 성공 후에만 트리거(로컬 저장은 항상 선행 → 유실 0 보존).

import Foundation

final class SyncingFeedingRepository: FeedingRepository {

    private let local: LocalFeedingRepository
    private let engine: FeedingSyncEngine

    init(local: LocalFeedingRepository, engine: FeedingSyncEngine) {
        self.local = local
        self.engine = engine
    }

    func create(_ feeding: Feeding) async throws -> Feeding {
        let saved = try await local.create(feeding)
        engine.triggerLocalChange()
        return saved
    }

    func update(_ feeding: Feeding) async throws -> Feeding {
        let saved = try await local.update(feeding)
        engine.triggerLocalChange()
        return saved
    }

    func delete(id: UUID, babyId: UUID) async throws {
        try await local.delete(id: id, babyId: babyId)
        engine.triggerLocalChange()
    }

    func fetch(id: UUID, babyId: UUID) async throws -> Feeding? {
        try await local.fetch(id: id, babyId: babyId)
    }

    func list(babyId: UUID, on day: Date) async throws -> [Feeding] {
        try await local.list(babyId: babyId, on: day)
    }

    func lastFeeding(babyId: UUID) async throws -> Feeding? {
        try await local.lastFeeding(babyId: babyId)
    }
}
