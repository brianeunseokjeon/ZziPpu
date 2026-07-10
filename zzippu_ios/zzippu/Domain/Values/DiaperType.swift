// Domain/Values/DiaperType.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

enum DiaperType: String, Codable, Sendable, CaseIterable {
    case pee  = "pee"
    case poo  = "poo"
    case both = "both"

    var displayName: String {
        switch self {
        case .pee:  return "소변"
        case .poo:  return "대변"
        case .both: return "소변+대변"
        }
    }

    var hasPoo: Bool { self == .poo || self == .both }
}

enum StoolColor: String, Codable, Sendable, CaseIterable {
    case yellow = "yellow"
    case green  = "green"
    case brown  = "brown"
    case black  = "black"
    case red    = "red"
    case white  = "white"

    var displayName: String {
        switch self {
        case .yellow: return "노란색"
        case .green:  return "초록색"
        case .brown:  return "갈색"
        case .black:  return "검정색"
        case .red:    return "빨간색"
        case .white:  return "흰색"
        }
    }

    var stoolSwatch: StoolSwatch {
        switch self {
        case .yellow: return .yellow
        case .green:  return .green
        case .brown:  return .brown
        case .black:  return .black
        case .red:    return .red
        case .white:  return .white
        }
    }
}

enum StoolState: String, Codable, Sendable, CaseIterable {
    case watery = "watery"
    case soft   = "soft"
    case normal = "normal"
    case hard   = "hard"

    var displayName: String {
        switch self {
        case .watery: return "묽음"
        case .soft:   return "부드러움"
        case .normal: return "보통"
        case .hard:   return "딱딱함"
        }
    }
}
