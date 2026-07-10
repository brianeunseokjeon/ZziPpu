// Domain/Entities/SleepRecord.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

struct SleepRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let babyId: UUID
    var startedAt: Date
    var endedAt: Date?          // nil = 진행중
    var durationMinutes: Int?   // 서버 계산값 (endedAt - startedAt)
    var memo: String?
    let createdAt: Date

    /// 진행중 여부
    var isActive: Bool { endedAt == nil }

    /// 경과 시간 (분, 진행중일 때 현재 시각 기준)
    func elapsedMinutes(now: Date = .now) -> Int {
        let end = endedAt ?? now
        return max(0, Int(end.timeIntervalSince(startedAt) / 60))
    }

    static func new(babyId: UUID, startedAt: Date = .now, memo: String? = nil) -> SleepRecord {
        SleepRecord(
            id: UUID(),
            babyId: babyId,
            startedAt: startedAt,
            endedAt: nil,
            durationMinutes: nil,
            memo: memo,
            createdAt: .now
        )
    }
}
