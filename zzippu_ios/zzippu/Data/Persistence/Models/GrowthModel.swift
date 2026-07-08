// Data/Persistence/Models/GrowthModel.swift

import Foundation
import SwiftData

@Model
final class GrowthModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var recordedAt: Date
    var weightG: Int?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var memo: String?
    var createdAt: Date
    // sync meta 4종
    var updatedAt: Date
    var syncStateRaw: Int
    var deletedAt: Date?

    init(id: UUID, babyId: UUID, recordedAt: Date,
         weightG: Int? = nil, heightCm: Double? = nil,
         headCircumferenceCm: Double? = nil, memo: String? = nil,
         createdAt: Date, updatedAt: Date,
         syncStateRaw: Int = SyncState.localOnly.rawValue,
         deletedAt: Date? = nil) {
        self.id = id
        self.babyId = babyId
        self.recordedAt = recordedAt
        self.weightG = weightG
        self.heightCm = heightCm
        self.headCircumferenceCm = headCircumferenceCm
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncStateRaw
        self.deletedAt = deletedAt
    }
}
