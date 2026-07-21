// Domain/Values/CareCategory.swift
// Foundation only — SwiftUI/SwiftData import 금지
// 통합 돌봄기록(CareLog)의 종류: 목욕·영양제·약.

import Foundation

enum CareCategory: String, Codable, Sendable, CaseIterable {
    case bath       = "bath"
    case supplement = "supplement"
    case medicine   = "medicine"

    var displayName: String {
        switch self {
        case .bath:       return "목욕"
        case .supplement: return "영양제"
        case .medicine:   return "약"
        }
    }

    var emoji: String {
        switch self {
        case .bath:       return "🛁"
        case .supplement: return "🧴"
        case .medicine:   return "💊"
        }
    }
}
