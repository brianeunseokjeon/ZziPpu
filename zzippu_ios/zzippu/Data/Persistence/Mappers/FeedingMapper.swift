// Data/Persistence/Mappers/FeedingMapper.swift

import Foundation

extension FeedingModel {
    /// Model → Domain Entity
    func toEntity() -> Feeding {
        Feeding(
            id: id,
            babyId: babyId,
            type: FeedingType(rawValue: feedingTypeRaw) ?? .formula,
            amountMl: amountMl,
            durationMinutes: durationMinutes,
            startedAt: startedAt,
            endedAt: endedAt,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: SyncState(rawValue: syncStateRaw) ?? .localOnly,
            deletedAt: deletedAt
        )
    }

    /// Domain Entity → 업데이트 매핑 (id/babyId/createdAt 불변)
    func apply(_ e: Feeding) {
        feedingTypeRaw = e.type.rawValue
        amountMl = e.amountMl
        durationMinutes = e.durationMinutes
        startedAt = e.startedAt
        endedAt = e.endedAt
        memo = e.memo
        updatedAt = e.updatedAt
        syncStateRaw = e.syncState.rawValue
        deletedAt = e.deletedAt
    }

    /// Domain Entity → 신규 Model 생성
    convenience init(from e: Feeding) {
        self.init(
            id: e.id,
            babyId: e.babyId,
            feedingTypeRaw: e.type.rawValue,
            amountMl: e.amountMl,
            durationMinutes: e.durationMinutes,
            startedAt: e.startedAt,
            endedAt: e.endedAt,
            memo: e.memo,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
            syncStateRaw: e.syncState.rawValue,
            deletedAt: e.deletedAt
        )
    }
}
