// Data/Network/DataSources/RemoteDevelopmentDataSource.swift
// 발달 콘텐츠 HTTP 호출 (읽기 전용, 인증 불필요 EP).

import Foundation

final class RemoteDevelopmentDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints (prefix: /api/v1/development)

    func currentStage(ageDays: Int) async throws -> CurrentStageBundleDTO {
        try await api.get(
            "/api/v1/development/stages/current",
            query: ["age_days": String(ageDays)]
        )
    }

    func milestones() async throws -> [MilestoneDTO] {
        try await api.get("/api/v1/development/milestones")
    }
}
