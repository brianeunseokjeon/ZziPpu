// Data/Repositories/RemoteGrowthRepository.swift
// GrowthRepository 프로토콜 구현 — RemoteGrowthDataSource + GrowthMapper

import Foundation

final class RemoteGrowthRepository: GrowthRepository {

    private let dataSource: RemoteGrowthDataSource

    init(api: APIClient) {
        self.dataSource = RemoteGrowthDataSource(api: api)
    }

    // MARK: - GrowthRepository

    func create(_ record: GrowthRecord) async throws -> GrowthRecord {
        let request = GrowthMapper.toCreateRequest(record)
        let dto = try await dataSource.create(babyId: record.babyId, request: request)
        return GrowthMapper.toEntity(dto)
    }

    func update(_ record: GrowthRecord) async throws -> GrowthRecord {
        let request = GrowthMapper.toUpdateRequest(record)
        let dto = try await dataSource.update(babyId: record.babyId, recordId: record.id, request: request)
        return GrowthMapper.toEntity(dto)
    }

    func delete(id: UUID, babyId: UUID) async throws {
        try await dataSource.delete(babyId: babyId, recordId: id)
    }

    func series(babyId: UUID) async throws -> [GrowthRecord] {
        let dtos = try await dataSource.series(babyId: babyId)
        return dtos.map { GrowthMapper.toEntity($0) }
    }
}
