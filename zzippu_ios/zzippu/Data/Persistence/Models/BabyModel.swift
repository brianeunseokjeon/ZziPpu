// Data/Persistence/Models/BabyModel.swift

import Foundation
import SwiftData

@Model
final class BabyModel {
    @Attribute(.unique) var id: UUID
    var userId: UUID?
    var name: String
    var birthDate: Date
    var genderRaw: String       // Gender raw: male/female/unknown
    var birthWeightG: Int?
    var photoData: Data?
    var createdAt: Date
    // sync meta 4종
    var updatedAt: Date
    var syncStateRaw: Int
    var deletedAt: Date?

    init(id: UUID, userId: UUID? = nil, name: String, birthDate: Date,
         genderRaw: String, birthWeightG: Int? = nil, photoData: Data? = nil,
         createdAt: Date, updatedAt: Date,
         syncStateRaw: Int = SyncState.localOnly.rawValue,
         deletedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.birthDate = birthDate
        self.genderRaw = genderRaw
        self.birthWeightG = birthWeightG
        self.photoData = photoData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncStateRaw
        self.deletedAt = deletedAt
    }
}
