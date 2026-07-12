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

    // MARK: - Range API (달력 월별 집계용, S3 추가)
    // 기존 list(on:)는 유지(하위호환). range는 추가만.
    /// KST 날짜 범위에 속하는 날별 총 수유량 집계 반환.
    /// - Parameters:
    ///   - babyId: 아기 UUID
    ///   - start: 범위 시작 KST 자정 (포함)
    ///   - end:   범위 끝 KST 자정 (포함)
    /// - Returns: [DateVolume] — day = KST 자정, totalMl = 당일 합산
    func dailyTotals(babyId: UUID, from start: Date, to end: Date) async throws -> [DateVolume]
}
