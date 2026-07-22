// Domain/Entities/GrowthRecord.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

struct GrowthRecord: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let babyId: UUID
    var recordedAt: Date
    var weightG: Int?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var temperatureC: Double?          // 체온(섭씨). 신체측정 한 세션에 함께 기록(선택).
    var memo: String?
    let createdAt: Date

    static func new(
        babyId: UUID,
        recordedAt: Date,
        weightG: Int? = nil,
        heightCm: Double? = nil,
        headCircumferenceCm: Double? = nil,
        temperatureC: Double? = nil,
        memo: String? = nil
    ) -> GrowthRecord {
        return GrowthRecord(
            id: UUID(),
            babyId: babyId,
            recordedAt: recordedAt,
            weightG: weightG,
            heightCm: heightCm,
            headCircumferenceCm: headCircumferenceCm,
            temperatureC: temperatureC,
            memo: memo,
            createdAt: Date.now
        )
    }
}
