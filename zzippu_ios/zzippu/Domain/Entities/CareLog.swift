// Domain/Entities/CareLog.swift
// Foundation only — SwiftUI/SwiftData import 금지
// 목욕·영양제·약 통합 기록. name/dose는 영양제·약에서만 사용(목욕은 nil).

import Foundation

struct CareLog: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let babyId: UUID
    var category: CareCategory
    var name: String?          // 프리셋 이름(예: "비타민D", "감기약"). 목욕/미선택은 nil.
    var dose: String?          // 용량 자유텍스트(예: "5방울", "2.5ml"). 선택.
    var recordedAt: Date
    var memo: String?
    let createdAt: Date

    static func new(
        babyId: UUID,
        category: CareCategory,
        name: String? = nil,
        dose: String? = nil,
        recordedAt: Date = .now,
        memo: String? = nil
    ) -> CareLog {
        CareLog(
            id: UUID(),
            babyId: babyId,
            category: category,
            name: name,
            dose: dose,
            recordedAt: recordedAt,
            memo: memo,
            createdAt: .now
        )
    }
}
