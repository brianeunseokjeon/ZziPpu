// Data/Network/DataSources/RemoteCareLogDataSource.swift
// CareLog 도메인 HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳

import Foundation

final class RemoteCareLogDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints (prefix: /api/v1/babies/{babyId}/care-logs)

    func list(babyId: UUID, date: String) async throws -> [CareLogResponseDTO] {
        try await api.get(
            "/api/v1/babies/\(babyId.uuidString)/care-logs",
            query: ["date": date]
        )
    }

    func create(babyId: UUID, request: CareLogCreateRequestDTO) async throws -> CareLogResponseDTO {
        try await api.post("/api/v1/babies/\(babyId.uuidString)/care-logs", body: request)
    }

    func update(babyId: UUID, careLogId: UUID, request: CareLogUpdateRequestDTO) async throws -> CareLogResponseDTO {
        try await api.patch("/api/v1/babies/\(babyId.uuidString)/care-logs/\(careLogId.uuidString)", body: request)
    }

    func delete(babyId: UUID, careLogId: UUID) async throws {
        try await api.delete("/api/v1/babies/\(babyId.uuidString)/care-logs/\(careLogId.uuidString)")
    }
}
