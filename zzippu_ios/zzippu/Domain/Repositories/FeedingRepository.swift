// Domain/Repositories/FeedingRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol FeedingRepository {
    func create(_ feeding: Feeding) async throws -> Feeding
    func update(_ feeding: Feeding) async throws -> Feeding
    func delete(id: UUID, babyId: UUID) async throws          // 서버 경로에 babyId 필요, 물리삭제(204)
    func fetch(id: UUID, babyId: UUID) async throws -> Feeding?
    func list(babyId: UUID, on day: Date) async throws -> [Feeding]
    func lastFeeding(babyId: UUID) async throws -> Feeding?   // list().first로 구현
}
