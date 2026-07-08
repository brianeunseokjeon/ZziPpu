// Data/Persistence/Mappers/BabyMapper.swift

import Foundation

extension BabyModel {
    /// Model → Domain Entity
    func toEntity() -> Baby {
        Baby(
            id: id,
            userId: userId,
            name: name,
            birthDate: birthDate,
            gender: Gender(rawValue: genderRaw) ?? .unknown,
            birthWeightG: birthWeightG,
            photoData: photoData,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: SyncState(rawValue: syncStateRaw) ?? .localOnly,
            deletedAt: deletedAt
        )
    }

    /// Domain Entity → 업데이트 매핑 (id/createdAt 불변)
    func apply(_ e: Baby) {
        userId = e.userId
        name = e.name
        birthDate = e.birthDate
        genderRaw = e.gender.rawValue
        birthWeightG = e.birthWeightG
        photoData = e.photoData
        updatedAt = e.updatedAt
        syncStateRaw = e.syncState.rawValue
        deletedAt = e.deletedAt
    }

    /// Domain Entity → 신규 Model 생성
    convenience init(from e: Baby) {
        self.init(
            id: e.id,
            userId: e.userId,
            name: e.name,
            birthDate: e.birthDate,
            genderRaw: e.gender.rawValue,
            birthWeightG: e.birthWeightG,
            photoData: e.photoData,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
            syncStateRaw: e.syncState.rawValue,
            deletedAt: e.deletedAt
        )
    }
}
