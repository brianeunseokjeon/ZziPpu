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
        let created = try await dataSource.create(babyId: sleep.babyId, request: SleepMapper.toStartRequest(sleep))
        // 기상 시각이 있으면(완료된 수면 기록) 바로 종료 처리 → 서버가 duration 계산.
        if let endedAt = sleep.endedAt {
            let ended = try await dataSource.end(
                babyId: sleep.babyId,
                sleepId: created.id,
                request: SleepMapper.toEndRequest(endedAt: endedAt)
            )
            return SleepMapper.toEntity(ended)
        }
        return SleepMapper.toEntity(created)
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
