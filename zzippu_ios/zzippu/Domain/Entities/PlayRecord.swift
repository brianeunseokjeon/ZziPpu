// Domain/Entities/PlayRecord.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

struct PlayRecord: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let babyId: UUID
    var playType: PlayType
    var startedAt: Date
    var endedAt: Date?
    var durationMinutes: Int?
    var memo: String?
    let createdAt: Date

    static func new(
        babyId: UUID,
        playType: PlayType,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        durationMinutes: Int? = nil,
        memo: String? = nil
    ) -> PlayRecord {
        PlayRecord(
            id: UUID(),
            babyId: babyId,
            playType: playType,
            startedAt: startedAt,
            endedAt: endedAt,
            durationMinutes: durationMinutes,
            memo: memo,
            createdAt: .now
        )
    }
}
