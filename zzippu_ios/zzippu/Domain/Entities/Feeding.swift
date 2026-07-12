// Domain/Entities/Feeding.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

struct Feeding: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let babyId: UUID
    var type: FeedingType
    var amountMl: Int?
    var durationMinutes: Int?
    var startedAt: Date
    var endedAt: Date?
    var memo: String?
    let createdAt: Date

    static func new(babyId: UUID, type: FeedingType, amountMl: Int? = nil,
                    durationMinutes: Int? = nil, startedAt: Date = .now,
                    endedAt: Date? = nil, memo: String? = nil) -> Feeding {
        return Feeding(id: UUID(), babyId: babyId, type: type,
                       amountMl: amountMl, durationMinutes: durationMinutes,
                       startedAt: startedAt, endedAt: endedAt, memo: memo,
                       createdAt: Date.now)
    }
}
