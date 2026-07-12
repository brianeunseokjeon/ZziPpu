// Data/Repositories/RemoteFeedingRepository.swift
// FeedingRepository 프로토콜 구현 — RemoteFeedingDataSource + FeedingMapper

import Foundation

final class RemoteFeedingRepository: FeedingRepository {

    private let dataSource: RemoteFeedingDataSource

    init(api: APIClient) {
        self.dataSource = RemoteFeedingDataSource(api: api)
    }

    // MARK: - FeedingRepository

    func create(_ feeding: Feeding) async throws -> Feeding {
        let request = FeedingMapper.toCreateRequest(feeding)
        let dto = try await dataSource.create(babyId: feeding.babyId, request: request)
        return FeedingMapper.toEntity(dto)
    }

    func update(_ feeding: Feeding) async throws -> Feeding {
        let request = FeedingMapper.toUpdateRequest(feeding)
        let dto = try await dataSource.update(
            babyId: feeding.babyId,
            feedingId: feeding.id,
            request: request
        )
        return FeedingMapper.toEntity(dto)
    }

    func delete(id: UUID, babyId: UUID) async throws {
        try await dataSource.delete(babyId: babyId, feedingId: id)
    }

    func fetch(id: UUID, babyId: UUID) async throws -> Feeding? {
        // 서버에 단일 조회 EP 없음 → list에서 탐색
        let dateStr = APIDateCodec.formatDate(Date.now)
        let all = try await dataSource.list(babyId: babyId, date: dateStr)
        return all.first(where: { $0.id == id }).map { FeedingMapper.toEntity($0) }
    }

    func list(babyId: UUID, on day: Date) async throws -> [Feeding] {
        let dateStr = APIDateCodec.formatDate(day)
        let dtos = try await dataSource.list(babyId: babyId, date: dateStr)
        return dtos.map { FeedingMapper.toEntity($0) }
    }

    func lastFeeding(babyId: UUID) async throws -> Feeding? {
        // 서버에 전용 EP 없음 → 오늘 목록에서 첫 항목 (서버가 최신순으로 반환)
        let dateStr = APIDateCodec.formatDate(Date.now)
        let dtos = try await dataSource.list(babyId: babyId, date: dateStr)
        return dtos.first.map { FeedingMapper.toEntity($0) }
    }

    /// 서버에 range EP 미지원 시 날짜별 N회 호출 폴백 — 오프라인 계층 킬스위치 정책과 정합.
    /// 향후 서버에 `/feedings/daily-totals?from=&to=` EP 추가 시 단일 호출로 교체 가능.
    func dailyTotals(babyId: UUID, from start: Date, to end: Date) async throws -> [DateVolume] {
        let cal = Calendar.kst
        var cursor = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        var results: [DateVolume] = []

        while cursor <= endDay {
            let dateStr = APIDateCodec.formatDate(cursor)
            let dtos = try await dataSource.list(babyId: babyId, date: dateStr)
            let total = dtos.reduce(0) { $0 + ($1.amountMl ?? 0) }
            if total > 0 {
                results.append(DateVolume(day: cursor, totalMl: total))
            }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }
        return results
    }
}
