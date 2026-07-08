// Domain/Values/SyncState.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

enum SyncState: Int, Codable, Sendable {
    case localOnly = 0   // 한 번도 서버에 안 감(신규 생성)
    case dirty     = 1   // 서버엔 있으나 로컬에서 수정됨(재push 필요)
    case synced    = 2   // 서버와 일치
}
