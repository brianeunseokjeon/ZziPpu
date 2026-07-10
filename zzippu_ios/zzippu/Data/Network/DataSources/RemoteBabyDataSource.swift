// Data/Network/DataSources/RemoteBabyDataSource.swift
// Baby 도메인 HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳

import Foundation

final class RemoteBabyDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints

    func fetchAll() async throws -> [BabyResponseDTO] {
        try await api.get("/api/v1/babies")
    }

    func fetch(id: UUID) async throws -> BabyResponseDTO {
        try await api.get("/api/v1/babies/\(id.uuidString)")
    }

    func create(_ request: BabyCreateRequestDTO) async throws -> BabyResponseDTO {
        try await api.post("/api/v1/babies", body: request)
    }

    func update(id: UUID, request: BabyUpdateRequestDTO) async throws -> BabyResponseDTO {
        try await api.patch("/api/v1/babies/\(id.uuidString)", body: request)
    }

    // MARK: - Caregiver (공유 합류)

    func joinByCode(_ request: CaregiverJoinRequestDTO) async throws -> BabyResponseDTO {
        try await api.post("/api/v1/caregivers/join", body: request)
    }
}
