// Data/Network/DataSources/RemoteVaccinationDataSource.swift
// Vaccination HTTP 호출 — 서버 경로·스키마를 아는 유일한 곳.

import Foundation

final class RemoteVaccinationDataSource {

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Endpoints (prefix: /api/v1/babies/{babyId}/vaccinations)

    func list(babyId: UUID) async throws -> [VaccinationResponseDTO] {
        try await api.get("/api/v1/babies/\(babyId.uuidString)/vaccinations")
    }

    func markAdministered(
        babyId: UUID,
        vaccinationId: UUID,
        request: MarkAdministeredRequestDTO
    ) async throws -> VaccinationResponseDTO {
        try await api.post(
            "/api/v1/babies/\(babyId.uuidString)/vaccinations/\(vaccinationId.uuidString)/administer",
            body: request
        )
    }
}
