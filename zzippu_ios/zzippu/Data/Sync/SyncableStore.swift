// Data/Sync/SyncableStore.swift
// Data 레이어 내부 프로토콜 — 동기화 엔진 전용 병합 훅.
// Domain 프로토콜이 아니라 Data 구체 타입(LocalFeedingRepository)에만 둔다 → Feature 오염 방지 (§4.1).

import Foundation

/// 동기화 엔진이 로컬 스토어를 push/pull 병합하기 위한 최소 인터페이스.
/// Feature/ViewModel 은 이 타입을 절대 보지 않는다.
protocol SyncableStore: Sendable {
    associatedtype Change: Sendable

    /// syncState != synced 인 레코드(localOnly + dirty + tombstone) — push 대상.
    func pendingChanges(babyId: UUID) async throws -> [Change]

    /// push 성공한 id들을 synced 로 전환하고 updatedAt 을 서버 시각으로 덮어쓴다.
    func markSynced(_ acks: [SyncAck]) async throws

    /// pull 받은 서버 레코드를 LWW + tombstone 규칙으로 로컬에 병합한다 (§4.4).
    func applyRemote(_ remotes: [Change]) async throws
}

/// push 응답의 accepted 항목 (서버가 재타임스탬프한 updatedAt 포함).
struct SyncAck: Sendable {
    let id: UUID
    let updatedAt: Date
}
