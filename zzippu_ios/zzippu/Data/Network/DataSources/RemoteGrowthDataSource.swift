// Data/Network/DataSources/RemoteGrowthDataSource.swift
// Growth 도메인 HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳

import Foundation

final class RemoteGrowthDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints (prefix: /api/v1/babies/{babyId}/growth)

    func series(babyId: UUID) async throws -> [GrowthResponseDTO] {
        try await api.get("/api/v1/babies/\(babyId.uuidString)/growth")
    }

    func create(babyId: UUID, request: GrowthCreateRequestDTO) async throws -> GrowthResponseDTO {
        try await api.post("/api/v1/babies/\(babyId.uuidString)/growth", body: request)
    }

    func update(babyId: UUID, recordId: UUID, request: GrowthUpdateRequestDTO) async throws -> GrowthResponseDTO {
        try await api.patch("/api/v1/babies/\(babyId.uuidString)/growth/\(recordId.uuidString)", body: request)
    }

    func delete(babyId: UUID, recordId: UUID) async throws {
        try await api.delete("/api/v1/babies/\(babyId.uuidString)/growth/\(recordId.uuidString)")
    }
}
