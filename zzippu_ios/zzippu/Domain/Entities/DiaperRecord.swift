// Domain/Entities/DiaperRecord.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

struct DiaperRecord: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let babyId: UUID
    var recordedAt: Date
    var diaperType: DiaperType
    var stoolColor: StoolColor?
    var stoolState: StoolState?
    /// 양(소변·대변 공통). nullable — 하위호환.
    var amount: DiaperAmount?
    var memo: String?
    let createdAt: Date

    static func new(
        babyId: UUID,
        diaperType: DiaperType,
        recordedAt: Date = .now,
        stoolColor: StoolColor? = nil,
        stoolState: StoolState? = nil,
        amount: DiaperAmount? = nil,
        memo: String? = nil
    ) -> DiaperRecord {
        DiaperRecord(
            id: UUID(),
            babyId: babyId,
            recordedAt: recordedAt,
            diaperType: diaperType,
            stoolColor: stoolColor,
            stoolState: stoolState,
            amount: amount,
            memo: memo,
            createdAt: .now
        )
    }
}
