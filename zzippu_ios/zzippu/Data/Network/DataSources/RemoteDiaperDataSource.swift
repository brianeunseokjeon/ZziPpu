// Data/Network/DataSources/RemoteDiaperDataSource.swift
// Diaper 도메인 HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳

import Foundation

final class RemoteDiaperDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints (prefix: /api/v1/babies/{babyId}/diapers)

    func list(babyId: UUID, date: String) async throws -> [DiaperResponseDTO] {
        try await api.get(
            "/api/v1/babies/\(babyId.uuidString)/diapers",
            query: ["date": date]
        )
    }

    func create(babyId: UUID, request: DiaperCreateRequestDTO) async throws -> DiaperResponseDTO {
        try await api.post("/api/v1/babies/\(babyId.uuidString)/diapers", body: request)
    }

    func delete(babyId: UUID, diaperId: UUID) async throws {
        try await api.delete("/api/v1/babies/\(babyId.uuidString)/diapers/\(diaperId.uuidString)")
    }
}
