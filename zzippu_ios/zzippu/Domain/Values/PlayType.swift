// Domain/Values/PlayType.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

enum PlayType: String, Codable, Sendable, CaseIterable {
    case tummyTime  = "tummy_time"
    case freePlay   = "free_play"
    case sensoryPlay = "sensory_play"

    var displayName: String {
        switch self {
        case .tummyTime:   return "터미타임"
        case .freePlay:    return "자유놀이"
        case .sensoryPlay: return "감각놀이"
        }
    }
}
