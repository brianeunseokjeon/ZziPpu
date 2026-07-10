// Data/Repositories/RemoteCaregiverRepository.swift
// CaregiverRepository 프로토콜 구현 — RemoteCaregiverDataSource + CaregiverMapper

import Foundation

final class RemoteCaregiverRepository: CaregiverRepository {

    private let dataSource: RemoteCaregiverDataSource

    init(api: APIClient) {
        self.dataSource = RemoteCaregiverDataSource(api: api)
    }

    // MARK: - CaregiverRepository

    func createInvite(babyId: UUID) async throws -> CaregiverInvite {
        let dto = try await dataSource.createInvite(babyId: babyId)
        return CaregiverMapper.toInvite(dto)
    }

    func listMembers(babyId: UUID) async throws -> [CaregiverMember] {
        let dtos = try await dataSource.listMembers(babyId: babyId)
        return dtos.map { CaregiverMapper.toMember($0) }
    }
}
