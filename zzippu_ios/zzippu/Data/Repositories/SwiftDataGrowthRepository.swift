// Data/Repositories/SwiftDataGrowthRepository.swift

import Foundation
import SwiftData

final class SwiftDataGrowthRepository: GrowthRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - CRUD

    func create(_ record: GrowthRecord) throws {
        let model = GrowthModel(from: record)
        context.insert(model)
        try context.save()
    }

    func update(_ record: GrowthRecord) throws {
        guard let model = try fetchModel(id: record.id) else { return }
        var next = record
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

    func fetch(id: UUID) throws -> GrowthRecord? {
        try fetchModel(id: id)?.toEntity()
    }

    func series(babyId: UUID) throws -> [GrowthRecord] {
        let predicate = #Predicate<GrowthModel> {
            $0.babyId == babyId && $0.deletedAt == nil
        }
        let descriptor = FetchDescriptor<GrowthModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt)]
        )
        return try context.fetch(descriptor).map { $0.toEntity() }
    }

    // MARK: - 동기화 훅 (MVP 미호출)

    func pendingSync(babyId: UUID) throws -> [GrowthRecord] {
        let syncedRaw = SyncState.synced.rawValue
        let predicate = #Predicate<GrowthModel> {
            $0.babyId == babyId && $0.syncStateRaw != syncedRaw
        }
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

    func applyRemote(_ remote: [GrowthRecord]) throws {
        for entity in remote {
            if let existing = try fetchModel(id: entity.id) {
                if entity.updatedAt > existing.updatedAt {
                    existing.apply(entity)
                }
            } else {
                context.insert(GrowthModel(from: entity))
            }
        }
        try context.save()
    }

    // MARK: - Private

    private func fetchModel(id: UUID) throws -> GrowthModel? {
        let predicate = #Predicate<GrowthModel> { $0.id == id }
        var descriptor = FetchDescriptor<GrowthModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
