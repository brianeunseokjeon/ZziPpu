// Data/Persistence/Models/FeedingModel.swift
// SwiftData @Model — feeding 도메인 필드 + sync 메타 4필드 (OFFLINE_SYNC_PLAN §2.1)
// server-first 전환 때 제거됐던 로컬 영속층을 feeding만 부활.

import Foundation
import SwiftData

@Model
final class FeedingModel {
    // MARK: - Sync 메타 (전 @Model 공통 4필드)
    @Attribute(.unique) var id: UUID
    var updatedAt: Date          // LWW 병합 기준 + push 후 서버 시각으로 덮어씀
    var syncStateRaw: Int        // localOnly(0)/dirty(1)/synced(2)
    var deletedAt: Date?         // tombstone (soft-delete)

    // MARK: - 도메인 필드
    var babyId: UUID
    var feedingTypeRaw: String
    var amountMl: Int?
    var durationMinutes: Int?
    var startedAt: Date
    var endedAt: Date?
    var memo: String?
    /// 먹고 토함 여부. SwiftData 경량 마이그레이션 위해 기본값 지정(기존 행은 false).
    var didVomit: Bool = false
    var createdAt: Date

    init(
        id: UUID,
        babyId: UUID,
        feedingTypeRaw: String,
        amountMl: Int?,
        durationMinutes: Int?,
        startedAt: Date,
        endedAt: Date?,
        memo: String?,
        didVomit: Bool = false,
        createdAt: Date,
        updatedAt: Date,
        syncStateRaw: Int,
        deletedAt: Date?
    ) {
        self.id = id
        self.babyId = babyId
        self.feedingTypeRaw = feedingTypeRaw
        self.amountMl = amountMl
        self.durationMinutes = durationMinutes
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.memo = memo
        self.didVomit = didVomit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncStateRaw
        self.deletedAt = deletedAt
    }

    // MARK: - Sync 메타 편의 접근
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
