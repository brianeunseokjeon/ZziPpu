// Data/Repositories/SwiftDataBabyRepository.swift

import Foundation
import SwiftData

final class SwiftDataBabyRepository: BabyRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - CRUD

    func create(_ baby: Baby) throws {
        let model = BabyModel(from: baby)
        context.insert(model)
        try context.save()
    }

    func update(_ baby: Baby) throws {
        guard let model = try fetchModel(id: baby.id) else { return }
        var next = baby
        next.updatedAt = .now
        if model.syncStateRaw == SyncState.synced.rawValue {
            next.syncState = .dirty
        }
        model.apply(next)
        try context.save()
    }

    func softDelete(id: UUID) throws {
        guard let model = try fetchModel(id: id) else { return }
        model.deletedAt = .now
        model.updatedAt = .now
        model.syncStateRaw = SyncState.dirty.rawValue
        try context.save()
    }

    func fetch(id: UUID) throws -> Baby? {
        try fetchModel(id: id)?.toEntity()
    }

    func fetchAll() throws -> [Baby] {
        let predicate = #Predicate<BabyModel> { $0.deletedAt == nil }
        let descriptor = FetchDescriptor<BabyModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor).map { $0.toEntity() }
    }

    /// 가장 최근에 생성된 삭제되지 않은 아기 반환 (MVP: 단일 아기)
    func activeBaby() throws -> Baby? {
        let predicate = #Predicate<BabyModel> { $0.deletedAt == nil }
        var descriptor = FetchDescriptor<BabyModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.toEntity()
    }

    // MARK: - 동기화 훅 (MVP 미호출)

    func pendingSync() throws -> [Baby] {
        let syncedRaw = SyncState.synced.rawValue
        let predicate = #Predicate<BabyModel> { $0.syncStateRaw != syncedRaw }
        return try context.fetch(FetchDescriptor(predicate: predicate)).map { $0.toEntity() }
    }

    func markSynced(ids: [UUID], serverTime: Date) throws {
        for id in ids {
            if let model = try fetchModel(id: id) {
                model.syncStateRaw = SyncState.synced.rawValue
                model.updatedAt = serverTime
            }
        }
        try context.save()
    }

    func applyRemote(_ remote: [Baby]) throws {
        for entity in remote {
            if let existing = try fetchModel(id: entity.id) {
                if entity.updatedAt > existing.updatedAt {
                    existing.apply(entity)
                }
            } else {
                context.insert(BabyModel(from: entity))
            }
        }
        try context.save()
    }

    // MARK: - Private

    private func fetchModel(id: UUID) throws -> BabyModel? {
        let predicate = #Predicate<BabyModel> { $0.id == id }
        var descriptor = FetchDescriptor<BabyModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
