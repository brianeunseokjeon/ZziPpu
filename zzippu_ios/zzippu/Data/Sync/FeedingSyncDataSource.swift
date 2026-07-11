// Data/Sync/FeedingSyncDataSource.swift
// 동기화 전용 HTTP 데이터소스 — /sync/push · /sync/pull 호출 (S1 API 계약).
// APIClient 를 그대로 재사용. FeedingChange ↔ FeedingSyncDTO 변환도 여기서.

import Foundation

struct FeedingSyncPushResult: Sendable {
    let serverTime: Date
    let accepted: [SyncAck]
}

struct FeedingSyncPullResult: Sendable {
    let serverTime: Date
    let feedings: [FeedingChange]
}

final class FeedingSyncDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Push

    func push(babyId: UUID, changes: [FeedingChange]) async throws -> FeedingSyncPushResult {
        let body = SyncPushRequestDTO(
            changes: SyncPushChangesDTO(feedings: changes.map(Self.toPushDTO))
        )
        let resp: SyncPushResponseDTO = try await api.post(
            "/api/v1/babies/\(babyId.uuidString)/sync/push", body: body
        )
        let acks = resp.accepted.map { SyncAck(id: $0.id, updatedAt: $0.updatedAt) }
        return FeedingSyncPushResult(serverTime: resp.serverTime, accepted: acks)
    }

    // MARK: - Pull

    /// since=nil 이면 전량(첫 동기화). 커서=응답 server_time.
    func pull(babyId: UUID, since: Date?) async throws -> FeedingSyncPullResult {
        var query: [String: String] = [:]
        if let since {
            query["since"] = APIDateCodec.formatDateTime(since)
        }
        let resp: SyncPullResponseDTO = try await api.get(
            "/api/v1/babies/\(babyId.uuidString)/sync/pull", query: query
        )
        let feedings = (resp.changes.feedings ?? []).map(Self.toChange)
        return FeedingSyncPullResult(serverTime: resp.serverTime, feedings: feedings)
    }

    // MARK: - Mapping

    private static func toPushDTO(_ c: FeedingChange) -> FeedingSyncDTO {
        FeedingSyncDTO(
            id: c.id, babyId: c.babyId, feedingType: c.feedingType,
            startedAt: c.startedAt, endedAt: c.endedAt, amountMl: c.amountMl,
            durationMinutes: c.durationMinutes, memo: c.memo,
            createdAt: c.createdAt, updatedAt: nil, deletedAt: c.deletedAt
        )
    }

    private static func toChange(_ d: FeedingSyncDTO) -> FeedingChange {
        FeedingChange(
            id: d.id, babyId: d.babyId, feedingType: d.feedingType,
            startedAt: d.startedAt, endedAt: d.endedAt, amountMl: d.amountMl,
            durationMinutes: d.durationMinutes, memo: d.memo,
            createdAt: d.createdAt ?? d.startedAt,
            updatedAt: d.updatedAt ?? d.startedAt,
            deletedAt: d.deletedAt
        )
    }
}
