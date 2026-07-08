// Data/Persistence/Mappers/GrowthMapper.swift

import Foundation

extension GrowthModel {
    /// Model → Domain Entity
    func toEntity() -> GrowthRecord {
        GrowthRecord(
            id: id,
            babyId: babyId,
            recordedAt: recordedAt,
            weightG: weightG,
            heightCm: heightCm,
            headCircumferenceCm: headCircumferenceCm,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: SyncState(rawValue: syncStateRaw) ?? .localOnly,
            deletedAt: deletedAt
        )
    }

    /// Domain Entity → 업데이트 매핑 (id/babyId/createdAt 불변)
    func apply(_ e: GrowthRecord) {
        recordedAt = e.recordedAt
        weightG = e.weightG
        heightCm = e.heightCm
        headCircumferenceCm = e.headCircumferenceCm
        memo = e.memo
        updatedAt = e.updatedAt
        syncStateRaw = e.syncState.rawValue
        deletedAt = e.deletedAt
    }

    /// Domain Entity → 신규 Model 생성
    convenience init(from e: GrowthRecord) {
        self.init(
            id: e.id,
            babyId: e.babyId,
            recordedAt: e.recordedAt,
            weightG: e.weightG,
            heightCm: e.heightCm,
            headCircumferenceCm: e.headCircumferenceCm,
            memo: e.memo,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
            syncStateRaw: e.syncState.rawValue,
            deletedAt: e.deletedAt
        )
    }
}
