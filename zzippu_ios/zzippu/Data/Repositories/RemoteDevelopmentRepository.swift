// Data/Repositories/RemoteDevelopmentRepository.swift
// DevelopmentRepository 구현 — RemoteDevelopmentDataSource + DevelopmentMapper.

import Foundation

final class RemoteDevelopmentRepository: DevelopmentRepository {

    private let dataSource: RemoteDevelopmentDataSource

    init(api: APIClient) {
        self.dataSource = RemoteDevelopmentDataSource(api: api)
    }

    func currentStage(ageDays: Int) async throws -> DevelopmentStageBundle {
        let dto = try await dataSource.currentStage(ageDays: ageDays)
        return DevelopmentMapper.toBundle(dto)
    }

    func milestones() async throws -> [Milestone] {
        let dtos = try await dataSource.milestones()
        return dtos.map(DevelopmentMapper.toEntity)
    }
}
