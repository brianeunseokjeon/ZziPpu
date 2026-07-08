// Domain/Values/FeedingType.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

enum FeedingType: String, Codable, Sendable, CaseIterable {
    case formula       = "formula"
    case breastLeft    = "breast_left"
    case breastRight   = "breast_right"
    case breastBoth    = "breast_both"

    var displayName: String {
        switch self {
        case .formula:     return "분유"
        case .breastLeft:  return "모유(좌)"
        case .breastRight: return "모유(우)"
        case .breastBoth:  return "모유(양쪽)"
        }
    }

    var isBreast: Bool {
        self == .breastLeft || self == .breastRight || self == .breastBoth
    }
}
