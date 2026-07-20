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
    /// 먹고 토했는지 여부(분유). true면 실제 섭취량이 준 양보다 적을 수 있음 → 타임라인 🤮 표시.
    var didVomit: Bool
    let createdAt: Date

    static func new(babyId: UUID, type: FeedingType, amountMl: Int? = nil,
                    durationMinutes: Int? = nil, startedAt: Date = .now,
                    endedAt: Date? = nil, memo: String? = nil,
                    didVomit: Bool = false) -> Feeding {
        return Feeding(id: UUID(), babyId: babyId, type: type,
                       amountMl: amountMl, durationMinutes: durationMinutes,
                       startedAt: startedAt, endedAt: endedAt, memo: memo,
                       didVomit: didVomit, createdAt: Date.now)
    }
}
