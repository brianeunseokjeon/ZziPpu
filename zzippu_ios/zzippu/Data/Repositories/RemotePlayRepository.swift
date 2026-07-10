// Data/Repositories/RemotePlayRepository.swift
// PlayRepository 프로토콜 구현 — RemotePlayDataSource + PlayMapper

import Foundation

final class RemotePlayRepository: PlayRepository {

    private let dataSource: RemotePlayDataSource

    init(api: APIClient) {
        self.dataSource = RemotePlayDataSource(api: api)
    }

    // MARK: - PlayRepository

    func create(_ play: PlayRecord) async throws -> PlayRecord {
        let request = PlayMapper.toCreateRequest(play)
        let dto = try await dataSource.create(babyId: play.babyId, request: request)
        return PlayMapper.toEntity(dto)
    }

    func delete(id: UUID, babyId: UUID) async throws {
        try await dataSource.delete(babyId: babyId, playId: id)
    }

    func list(babyId: UUID, on day: Date) async throws -> [PlayRecord] {
        let dateStr = APIDateCodec.formatDate(day)
        let dtos = try await dataSource.list(babyId: babyId, date: dateStr)
        return dtos.map { PlayMapper.toEntity($0) }
    }
}
