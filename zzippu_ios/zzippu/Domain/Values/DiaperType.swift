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

/// 기저귀 양(소변·대변 공통). 백엔드 계약: little|normal|lot, nullable(snake_case 불필요 — 단일단어).
enum DiaperAmount: String, Codable, Sendable, CaseIterable {
    case little = "little"
    case normal = "normal"
    case lot    = "lot"

    var displayName: String {
        switch self {
        case .little: return "적게"
        case .normal: return "보통"
        case .lot:    return "많이"
        }
    }
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

    // MARK: - 기저귀(대변) 색 선택지 (사용자 요청: 황금똥/초록색/검은색/붉은색/보통)

    /// 대변 색 칩 목록·순서. yellow=황금똥, brown=보통으로 컨텍스트 라벨링(흰색은 미노출).
    static let diaperColorCases: [StoolColor] = [.yellow, .green, .black, .red, .brown]

    /// 기저귀 컨텍스트 라벨. 전역 displayName과 별개(enum 값 불변 → 하위호환).
    var diaperColorLabel: String {
        switch self {
        case .yellow: return "황금똥"
        case .green:  return "초록색"
        case .black:  return "검은색"
        case .red:    return "붉은색"
        case .brown:  return "보통"
        case .white:  return "흰색"
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

    /// 기저귀 컨텍스트의 '질감' 라벨. 전역 displayName(딱딱함)과 분리.
    /// watery=묽음 / normal=보통 / hard=찰흙 / soft=부드러움.
    var textureShortLabel: String {
        switch self {
        case .watery: return "묽음"
        case .soft:   return "부드러움"
        case .normal: return "보통"
        case .hard:   return "찰흙"
        }
    }

    /// 기저귀 UI에 노출하는 질감 3칩(묽음/보통/찰흙). soft·기타는 미노출.
    static let diaperTextureCases: [StoolState] = [.watery, .normal, .hard]
}
