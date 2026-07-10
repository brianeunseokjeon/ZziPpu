// Data/Network/DataSources/RemotePlayDataSource.swift
// Play 도메인 HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳

import Foundation

final class RemotePlayDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints (prefix: /api/v1/babies/{babyId}/plays)

    func list(babyId: UUID, date: String) async throws -> [PlayResponseDTO] {
        try await api.get(
            "/api/v1/babies/\(babyId.uuidString)/plays",
            query: ["date": date]
        )
    }

    func create(babyId: UUID, request: PlayCreateRequestDTO) async throws -> PlayResponseDTO {
        try await api.post("/api/v1/babies/\(babyId.uuidString)/plays", body: request)
    }

    func delete(babyId: UUID, playId: UUID) async throws {
        try await api.delete("/api/v1/babies/\(babyId.uuidString)/plays/\(playId.uuidString)")
    }
}
