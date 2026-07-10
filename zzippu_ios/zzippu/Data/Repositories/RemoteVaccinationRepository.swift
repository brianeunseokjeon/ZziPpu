// Data/Repositories/RemoteVaccinationRepository.swift
// VaccinationRepository 구현 — RemoteVaccinationDataSource + VaccinationMapper.

import Foundation

final class RemoteVaccinationRepository: VaccinationRepository {

    private let dataSource: RemoteVaccinationDataSource

    init(api: APIClient) {
        self.dataSource = RemoteVaccinationDataSource(api: api)
    }

    func list(babyId: UUID) async throws -> [Vaccination] {
        let dtos = try await dataSource.list(babyId: babyId)
        return dtos.map(VaccinationMapper.toEntity)
    }

    func markAdministered(
        babyId: UUID,
        id: UUID,
        administeredDate: Date,
        hospitalName: String?
    ) async throws -> Vaccination {
        let request = VaccinationMapper.toMarkRequest(
            administeredDate: administeredDate,
            hospitalName: hospitalName
        )
        let dto = try await dataSource.markAdministered(
            babyId: babyId,
            vaccinationId: id,
            request: request
        )
        return VaccinationMapper.toEntity(dto)
    }
}
