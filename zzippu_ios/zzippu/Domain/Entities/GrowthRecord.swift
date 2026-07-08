// Domain/Entities/GrowthRecord.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

struct GrowthRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let babyId: UUID
    var recordedAt: Date
    var weightG: Int?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var memo: String?
    let createdAt: Date
    var updatedAt: Date
    var syncState: SyncState
    var deletedAt: Date?

    static func new(
        babyId: UUID,
        recordedAt: Date,
        weightG: Int? = nil,
        heightCm: Double? = nil,
        headCircumferenceCm: Double? = nil,
        memo: String? = nil
    ) -> GrowthRecord {
        let now = Date.now
        return GrowthRecord(
            id: UUID(),
            babyId: babyId,
            recordedAt: recordedAt,
            weightG: weightG,
            heightCm: heightCm,
            headCircumferenceCm: headCircumferenceCm,
            memo: memo,
            createdAt: now,
            updatedAt: now,
            syncState: .localOnly,
            deletedAt: nil
        )
    }
}
