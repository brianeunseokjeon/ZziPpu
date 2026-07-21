// Data/Repositories/RemoteCareLogRepository.swift
// CareLogRepository 프로토콜 구현 — RemoteCareLogDataSource + CareLogMapper

import Foundation

final class RemoteCareLogRepository: CareLogRepository {

    private let dataSource: RemoteCareLogDataSource

    init(api: APIClient) {
        self.dataSource = RemoteCareLogDataSource(api: api)
    }

    // MARK: - CareLogRepository

    func create(_ log: CareLog) async throws -> CareLog {
        let request = CareLogMapper.toCreateRequest(log)
        let dto = try await dataSource.create(babyId: log.babyId, request: request)
        return CareLogMapper.toEntity(dto)
    }

    func update(_ log: CareLog) async throws -> CareLog {
        let request = CareLogMapper.toUpdateRequest(log)
        let dto = try await dataSource.update(babyId: log.babyId, careLogId: log.id, request: request)
        return CareLogMapper.toEntity(dto)
    }

    func delete(id: UUID, babyId: UUID) async throws {
        try await dataSource.delete(babyId: babyId, careLogId: id)
    }

    func list(babyId: UUID, on day: Date) async throws -> [CareLog] {
        let dateStr = APIDateCodec.formatDate(day)
        let dtos = try await dataSource.list(babyId: babyId, date: dateStr)
        return dtos.map { CareLogMapper.toEntity($0) }
    }
}
