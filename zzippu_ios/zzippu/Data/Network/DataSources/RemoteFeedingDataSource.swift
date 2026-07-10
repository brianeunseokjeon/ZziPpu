// Data/Network/DataSources/RemoteFeedingDataSource.swift
// Feeding 도메인 HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳

import Foundation

final class RemoteFeedingDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints (prefix: /api/v1/babies/{babyId}/feedings)

    func list(babyId: UUID, date: String) async throws -> [FeedingResponseDTO] {
        try await api.get(
            "/api/v1/babies/\(babyId.uuidString)/feedings",
            query: ["date": date]
        )
    }

    func create(babyId: UUID, request: FeedingCreateRequestDTO) async throws -> FeedingResponseDTO {
        try await api.post("/api/v1/babies/\(babyId.uuidString)/feedings", body: request)
    }

    func update(babyId: UUID, feedingId: UUID, request: FeedingUpdateRequestDTO) async throws -> FeedingResponseDTO {
        try await api.patch(
            "/api/v1/babies/\(babyId.uuidString)/feedings/\(feedingId.uuidString)",
            body: request
        )
    }

    func delete(babyId: UUID, feedingId: UUID) async throws {
        try await api.delete("/api/v1/babies/\(babyId.uuidString)/feedings/\(feedingId.uuidString)")
    }
}
