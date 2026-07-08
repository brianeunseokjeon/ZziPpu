// Data/Persistence/Models/FeedingModel.swift

import Foundation
import SwiftData

@Model
final class FeedingModel {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var feedingTypeRaw: String        // FeedingType raw
    var amountMl: Int?
    var durationMinutes: Int?
    var startedAt: Date
    var endedAt: Date?
    var memo: String?
    var createdAt: Date
    // sync meta 4종
    var updatedAt: Date
    var syncStateRaw: Int
    var deletedAt: Date?

    init(id: UUID, babyId: UUID, feedingTypeRaw: String,
         amountMl: Int? = nil, durationMinutes: Int? = nil,
         startedAt: Date, endedAt: Date? = nil, memo: String? = nil,
         createdAt: Date, updatedAt: Date,
         syncStateRaw: Int = SyncState.localOnly.rawValue,
         deletedAt: Date? = nil) {
        self.id = id
        self.babyId = babyId
        self.feedingTypeRaw = feedingTypeRaw
        self.amountMl = amountMl
        self.durationMinutes = durationMinutes
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncStateRaw
        self.deletedAt = deletedAt
    }
}
