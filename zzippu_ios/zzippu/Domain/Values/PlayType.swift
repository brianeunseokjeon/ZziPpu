// Domain/Values/PlayType.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

enum PlayType: String, Codable, Sendable, CaseIterable {
    case tummyTime = "tummy_time"   // 터미타임만 사용(자유/감각놀이 제거)

    var displayName: String { "터미타임" }
}
