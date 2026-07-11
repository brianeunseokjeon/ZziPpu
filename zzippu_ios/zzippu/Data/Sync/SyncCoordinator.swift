// Data/Sync/SyncCoordinator.swift
// 전역 동기화 상태 노출 (@Observable) — UI는 관찰만. 표시 UI는 S5 슬라이스.
// SyncEngine 이 상태를 갱신하고, Feature 는 엔티티 오염 없이 이 하나만 본다 (§6).

import Foundation
import Observation

enum SyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case offline
    case error(String)
}

@MainActor
@Observable
final class SyncCoordinator {
    /// 현재 동기화 상태 (UI 상태줄용 — S5에서 소비)
    private(set) var status: SyncStatus = .idle
    /// 마지막 성공 시각
    private(set) var lastSyncedAt: Date?
    /// 미전송(dirty) 추정 건수 안내용 (선택)
    private(set) var pendingCount: Int = 0

    /// nonisolated: AppContainer 의 nonisolated init 에서 생성 가능하게 (상태는 기본값만).
    nonisolated init() {}

    func setSyncing() { status = .syncing }
    func setIdle() { status = .idle; lastSyncedAt = .now }
    func setOffline() { status = .offline }
    func setError(_ message: String) { status = .error(message) }
    func setPending(_ n: Int) { pendingCount = n }
}
