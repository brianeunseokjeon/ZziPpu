// Data/Repositories/RemoteBabyRepository.swift
// BabyRepository 프로토콜 구현 — RemoteBabyDataSource + BabyMapper

import Foundation

final class RemoteBabyRepository: BabyRepository {

    private let dataSource: RemoteBabyDataSource

    init(api: APIClient) {
        self.dataSource = RemoteBabyDataSource(api: api)
    }

    // MARK: - BabyRepository

    func fetchAll() async throws -> [Baby] {
        let dtos = try await dataSource.fetchAll()
        return dtos.map { BabyMapper.toEntity($0) }
    }

    func fetch(id: UUID) async throws -> Baby? {
        do {
            let dto = try await dataSource.fetch(id: id)
            return BabyMapper.toEntity(dto)
        } catch APIError.notFound {
            return nil
        }
    }

    func create(_ baby: Baby) async throws -> Baby {
        let request = BabyMapper.toCreateRequest(baby)
        let dto = try await dataSource.create(request)
        return BabyMapper.toEntity(dto)
    }

    func update(_ baby: Baby) async throws -> Baby {
        let request = BabyMapper.toUpdateRequest(baby)
        let dto = try await dataSource.update(id: baby.id, request: request)
        return BabyMapper.toEntity(dto)
    }

    /// MVP: 서버에 baby 삭제 EP 없음 → 미구현
    // softDelete는 BabyRepository 프로토콜에서 제거됨

    func activeBaby() async throws -> Baby? {
        let all = try await fetchAll()
        return all.first
    }

    func joinByCode(_ code: String) async throws -> Baby {
        let request = CaregiverJoinRequestDTO(code: code)
        let dto = try await dataSource.joinByCode(request)
        return BabyMapper.toEntity(dto)
    }
}
