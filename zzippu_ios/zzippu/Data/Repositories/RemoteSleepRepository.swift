// Data/Repositories/RemoteSleepRepository.swift
// SleepRepository 프로토콜 구현 — RemoteSleepDataSource + SleepMapper

import Foundation

final class RemoteSleepRepository: SleepRepository {

    private let dataSource: RemoteSleepDataSource

    init(api: APIClient) {
        self.dataSource = RemoteSleepDataSource(api: api)
    }

    // MARK: - SleepRepository

    func create(_ sleep: SleepRecord) async throws -> SleepRecord {
        let request = SleepMapper.toStartRequest(sleep)
        let dto = try await dataSource.create(babyId: sleep.babyId, request: request)
        return SleepMapper.toEntity(dto)
    }

    func endSleep(id: UUID, babyId: UUID, endedAt: Date) async throws -> SleepRecord {
        let request = SleepMapper.toEndRequest(endedAt: endedAt)
        let dto = try await dataSource.end(babyId: babyId, sleepId: id, request: request)
        return SleepMapper.toEntity(dto)
    }

    func delete(id: UUID, babyId: UUID) async throws {
        try await dataSource.delete(babyId: babyId, sleepId: id)
    }

    func list(babyId: UUID, on day: Date) async throws -> [SleepRecord] {
        let dateStr = APIDateCodec.formatDate(day)
        let dtos = try await dataSource.list(babyId: babyId, date: dateStr)
        return dtos.map { SleepMapper.toEntity($0) }
    }

    func activeSession(babyId: UUID) async throws -> SleepRecord? {
        guard let dto = try await dataSource.activeSession(babyId: babyId) else { return nil }
        return SleepMapper.toEntity(dto)
    }
}
