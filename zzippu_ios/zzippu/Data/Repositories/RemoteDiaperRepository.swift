// Data/Repositories/RemoteDiaperRepository.swift
// DiaperRepository 프로토콜 구현 — RemoteDiaperDataSource + DiaperMapper

import Foundation

final class RemoteDiaperRepository: DiaperRepository {

    private let dataSource: RemoteDiaperDataSource

    init(api: APIClient) {
        self.dataSource = RemoteDiaperDataSource(api: api)
    }

    // MARK: - DiaperRepository

    func create(_ diaper: DiaperRecord) async throws -> DiaperRecord {
        let request = DiaperMapper.toCreateRequest(diaper)
        let dto = try await dataSource.create(babyId: diaper.babyId, request: request)
        return DiaperMapper.toEntity(dto)
    }

    func delete(id: UUID, babyId: UUID) async throws {
        try await dataSource.delete(babyId: babyId, diaperId: id)
    }

    func list(babyId: UUID, on day: Date) async throws -> [DiaperRecord] {
        let dateStr = APIDateCodec.formatDate(day)
        let dtos = try await dataSource.list(babyId: babyId, date: dateStr)
        return dtos.map { DiaperMapper.toEntity($0) }
    }
}
