// Data/Network/DataSources/RemoteSleepDataSource.swift
// Sleep 도메인 HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳

import Foundation

final class RemoteSleepDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints (prefix: /api/v1/babies/{babyId}/sleeps)

    func list(babyId: UUID, date: String) async throws -> [SleepResponseDTO] {
        try await api.get(
            "/api/v1/babies/\(babyId.uuidString)/sleeps",
            query: ["date": date]
        )
    }

    func create(babyId: UUID, request: SleepStartRequestDTO) async throws -> SleepResponseDTO {
        try await api.post("/api/v1/babies/\(babyId.uuidString)/sleeps", body: request)
    }

    func end(babyId: UUID, sleepId: UUID, request: SleepEndRequestDTO) async throws -> SleepResponseDTO {
        try await api.put(
            "/api/v1/babies/\(babyId.uuidString)/sleeps/\(sleepId.uuidString)/end",
            body: request
        )
    }

    func delete(babyId: UUID, sleepId: UUID) async throws {
        try await api.delete("/api/v1/babies/\(babyId.uuidString)/sleeps/\(sleepId.uuidString)")
    }

    func activeSession(babyId: UUID) async throws -> SleepResponseDTO? {
        // GET /sleeps/active → SleepResponse | None
        // 서버가 null 반환 시 nil 처리
        let result: SleepResponseDTO? = try await api.get(
            "/api/v1/babies/\(babyId.uuidString)/sleeps/active"
        )
        return result
    }
}
