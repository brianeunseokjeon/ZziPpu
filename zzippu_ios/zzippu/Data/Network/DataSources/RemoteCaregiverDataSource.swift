// Data/Network/DataSources/RemoteCaregiverDataSource.swift
// 공동양육 HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳.

import Foundation

final class RemoteCaregiverDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints

    /// 초대코드 발급 — POST /babies/{id}/caregivers/invite (바디 없음)
    func createInvite(babyId: UUID) async throws -> CaregiverInviteResponseDTO {
        try await api.post(
            "/api/v1/babies/\(babyId.uuidString)/caregivers/invite",
            body: EmptyInviteBody()
        )
    }

    /// 멤버 목록 — GET /babies/{id}/caregivers
    func listMembers(babyId: UUID) async throws -> [CaregiverMemberResponseDTO] {
        try await api.get("/api/v1/babies/\(babyId.uuidString)/caregivers")
    }
}

/// invite 발급은 바디가 없으나 APIClient.post 는 Encodable 바디를 요구 → 빈 객체.
private struct EmptyInviteBody: Encodable {}
