// Data/Persistence/Mappers/FeedingModelMapper.swift
// Feeding(Domain struct) ↔ FeedingModel(@Model)
// Domain 엔티티는 순수 유지(sync 메타 없음) — Mapper가 메타 주입/제거 (OFFLINE_SYNC_PLAN §2.2 (b) 채택)

import Foundation

enum FeedingModelMapper {

    // MARK: - Model → Entity (sync 메타 제거)

    static func toEntity(_ model: FeedingModel) -> Feeding {
        Feeding(
            id: model.id,
            babyId: model.babyId,
            type: FeedingType(rawValue: model.feedingTypeRaw) ?? .formula,
            amountMl: model.amountMl,
            durationMinutes: model.durationMinutes,
            startedAt: model.startedAt,
            endedAt: model.endedAt,
            memo: model.memo,
            createdAt: model.createdAt
        )
    }

    // MARK: - Entity → Model (신규 insert 시 메타 주입)

    /// create 경로: syncState=.localOnly, updatedAt=.now
    static func makeModel(from entity: Feeding, updatedAt: Date = .now,
                          syncState: SyncState = .localOnly) -> FeedingModel {
        FeedingModel(
            id: entity.id,
            babyId: entity.babyId,
            feedingTypeRaw: entity.type.rawValue,
            amountMl: entity.amountMl,
            durationMinutes: entity.durationMinutes,
            startedAt: entity.startedAt,
            endedAt: entity.endedAt,
            memo: entity.memo,
            createdAt: entity.createdAt,
            updatedAt: updatedAt,
            syncStateRaw: syncState.rawValue,
            deletedAt: nil
        )
    }

    // MARK: - Entity 필드를 기존 Model에 반영 (update 경로 — 메타는 호출부가 결정)

    static func apply(_ entity: Feeding, to model: FeedingModel) {
        model.babyId = entity.babyId
        model.feedingTypeRaw = entity.type.rawValue
        model.amountMl = entity.amountMl
        model.durationMinutes = entity.durationMinutes
        model.startedAt = entity.startedAt
        model.endedAt = entity.endedAt
        model.memo = entity.memo
        // createdAt/id 는 불변
    }
}
