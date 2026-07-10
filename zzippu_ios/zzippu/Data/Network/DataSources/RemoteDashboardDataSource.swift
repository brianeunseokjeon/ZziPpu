// Data/Network/DataSources/RemoteDashboardDataSource.swift
// Dashboard HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳

import Foundation

final class RemoteDashboardDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - GET /api/v1/babies/{babyId}/dashboard/daily?date=YYYY-MM-DD

    func dailySummary(babyId: UUID, date: String) async throws -> DailySummaryResponseDTO {
        try await api.get(
            "/api/v1/babies/\(babyId.uuidString)/dashboard/daily",
            query: ["date": date]
        )
    }

    // MARK: - GET /api/v1/babies/{babyId}/dashboard/predictions

    func predictions(babyId: UUID) async throws -> PredictionResponseDTO {
        try await api.get("/api/v1/babies/\(babyId.uuidString)/dashboard/predictions")
    }
}
