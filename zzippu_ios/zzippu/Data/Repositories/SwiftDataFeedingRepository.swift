// Data/Repositories/SwiftDataFeedingRepository.swift

import Foundation
import SwiftData

final class SwiftDataFeedingRepository: FeedingRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - CRUD

    func create(_ feeding: Feeding) throws {
        let model = FeedingModel(from: feeding)
        context.insert(model)
        try context.save()
    }

    func update(_ feeding: Feeding) throws {
        guard let model = try fetchModel(id: feeding.id) else { return }
        var next = feeding
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

    func fetch(id: UUID) throws -> Feeding? {
        try fetchModel(id: id)?.toEntity()
    }

    func list(babyId: UUID, on day: Date) throws -> [Feeding] {
        let (start, end) = day.dayBounds
        let predicate = #Predicate<FeedingModel> {
            $0.babyId == babyId &&
            $0.deletedAt == nil &&
            $0.startedAt >= start &&
            $0.startedAt < end
        }
        let descriptor = FetchDescriptor<FeedingModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toEntity() }
    }

    func lastFeeding(babyId: UUID) throws -> Feeding? {
        let predicate = #Predicate<FeedingModel> {
            $0.babyId == babyId && $0.deletedAt == nil
        }
        var descriptor = FetchDescriptor<FeedingModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.toEntity()
    }

    // MARK: - 동기화 훅 (MVP에서는 미호출)

    func pendingSync(babyId: UUID) throws -> [Feeding] {
        let syncedRaw = SyncState.synced.rawValue
        let predicate = #Predicate<FeedingModel> {
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

    func applyRemote(_ remote: [Feeding]) throws {
        for entity in remote {
            if let existing = try fetchModel(id: entity.id) {
                // LWW: 원격이 더 최신이면 덮어씀
                if entity.updatedAt > existing.updatedAt {
                    existing.apply(entity)
                }
            } else {
                context.insert(FeedingModel(from: entity))
            }
        }
        try context.save()
    }

    // MARK: - Private

    private func fetchModel(id: UUID) throws -> FeedingModel? {
        let predicate = #Predicate<FeedingModel> { $0.id == id }
        var descriptor = FetchDescriptor<FeedingModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
