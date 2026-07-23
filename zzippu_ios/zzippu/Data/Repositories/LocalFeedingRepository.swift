// Data/Repositories/LocalFeedingRepository.swift
// FeedingRepository 프로토콜(무변경) 구현 — 로컬 SwiftData 즉시 R/W. 오프라인 완결.
// 추가로 SyncableStore(Data 내부 프로토콜) 구현 — 동기화 엔진용 병합 훅.
// @ModelActor: ModelContext 를 액터에 구속해 async throws 시그니처를 안전하게 만족.

import Foundation
import SwiftData

@ModelActor
actor LocalFeedingRepository: FeedingRepository, SyncableStore {

    typealias Change = FeedingChange

    // MARK: - FeedingRepository (Domain 프로토콜 무변경)

    /// create: insert, localOnly + updatedAt=.now. 즉시 엔티티 반환(서버 왕복 없음).
    func create(_ feeding: Feeding) async throws -> Feeding {
        let model = FeedingModelMapper.makeModel(from: feeding, updatedAt: .now, syncState: .localOnly)
        modelContext.insert(model)
        try modelContext.save()
        return FeedingModelMapper.toEntity(model)
    }

    /// update: updatedAt=.now. synced였으면 dirty로, localOnly면 유지.
    func update(_ feeding: Feeding) async throws -> Feeding {
        guard let model = try findModel(id: feeding.id) else {
            // 로컬에 없으면 신규로 취급(유실 방지)
            return try await create(feeding)
        }
        FeedingModelMapper.apply(feeding, to: model)
        model.updatedAt = .now
        if model.syncState == .synced { model.syncState = .dirty }
        try modelContext.save()
        return FeedingModelMapper.toEntity(model)
    }

    /// delete: tombstone(deletedAt=now, dirty). localOnly였다면 물리삭제(서버가 모르는 레코드).
    func delete(id: UUID, babyId: UUID) async throws {
        guard let model = try findModel(id: id) else { return }
        if model.syncState == .localOnly {
            modelContext.delete(model)   // 서버에 없으니 흔적 남길 필요 없음
        } else {
            model.deletedAt = .now
            model.updatedAt = .now
            model.syncState = .dirty
        }
        try modelContext.save()
    }

    func fetch(id: UUID, babyId: UUID) async throws -> Feeding? {
        guard let model = try findModel(id: id), model.deletedAt == nil else { return nil }
        return FeedingModelMapper.toEntity(model)
    }

    /// 로그아웃/계정 전환 시 로컬 전량 물리삭제(계정 간 기록 잔존·오염 방지).
    /// 서버가 진실원천이므로 tombstone 없이 삭제 — 다음 로그인 때 since=nil 전량 pull로 재수신.
    func deleteAllLocal() async throws {
        try modelContext.delete(model: FeedingModel.self)
        try modelContext.save()
    }

    /// list: 해당 날짜(로컬 자정~자정) + deletedAt==nil 필터.
    func list(babyId: UUID, on day: Date) async throws -> [Feeding] {
        let cal = Calendar.kst
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let predicate = #Predicate<FeedingModel> { m in
            m.babyId == babyId && m.deletedAt == nil &&
            m.startedAt >= start && m.startedAt < end
        }
        var descriptor = FetchDescriptor<FeedingModel>(predicate: predicate,
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        descriptor.fetchLimit = nil
        let models = try modelContext.fetch(descriptor)
        return models.map(FeedingModelMapper.toEntity)
    }

    func lastFeeding(babyId: UUID) async throws -> Feeding? {
        let predicate = #Predicate<FeedingModel> { m in
            m.babyId == babyId && m.deletedAt == nil
        }
        var descriptor = FetchDescriptor<FeedingModel>(predicate: predicate,
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map(FeedingModelMapper.toEntity)
    }

    /// 날짜 범위 내 날별 총 수유량 집계 — 로컬 SwiftData 단일 쿼리(N+1 없음).
    /// KST 경계: startedAt >= start(KST 자정) && startedAt < end 다음날 자정.
    func dailyTotals(babyId: UUID, from start: Date, to end: Date) async throws -> [DateVolume] {
        let cal = Calendar.kst
        // end 다음날 자정(= end 포함한 범위 끝)
        let endExclusive = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: end)) ?? end

        let predicate = #Predicate<FeedingModel> { m in
            m.babyId == babyId && m.deletedAt == nil &&
            m.startedAt >= start && m.startedAt < endExclusive
        }
        let descriptor = FetchDescriptor<FeedingModel>(predicate: predicate)
        let models = try modelContext.fetch(descriptor)

        // KST 날짜별 ml 합산
        var buckets: [Date: Int] = [:]
        for m in models {
            let day = cal.startOfDay(for: m.startedAt)
            buckets[day, default: 0] += m.amountMl ?? 0
        }
        return buckets.map { DateVolume(day: $0.key, totalMl: $0.value) }
            .sorted { $0.day < $1.day }
    }

    // MARK: - SyncableStore (동기화 엔진 전용)

    /// syncState != synced 인 모든 레코드(tombstone 포함) — push 대상.
    func pendingChanges(babyId: UUID) async throws -> [FeedingChange] {
        let syncedRaw = SyncState.synced.rawValue
        let predicate = #Predicate<FeedingModel> { m in
            m.babyId == babyId && m.syncStateRaw != syncedRaw
        }
        let descriptor = FetchDescriptor<FeedingModel>(predicate: predicate)
        return try modelContext.fetch(descriptor).map(Self.toChange)
    }

    /// push accepted → synced 전환 + updatedAt 서버 시각으로 덮어쓰기.
    func markSynced(_ acks: [SyncAck]) async throws {
        guard !acks.isEmpty else { return }
        var map: [UUID: Date] = [:]
        for a in acks { map[a.id] = a.updatedAt }
        let ids = Array(map.keys)
        let predicate = #Predicate<FeedingModel> { m in ids.contains(m.id) }
        let models = try modelContext.fetch(FetchDescriptor<FeedingModel>(predicate: predicate))
        for m in models {
            if let serverTime = map[m.id] {
                // markSynced 이후 로컬이 또 수정됐다면(dirty 유지) 덮어쓰지 않음(레이스 보호).
                // 여기서는 push한 스냅샷 기준이므로, 서버시각이 로컬보다 크거나 같을 때만 synced.
                if m.updatedAt <= serverTime {
                    m.updatedAt = serverTime
                    m.syncState = .synced
                }
            }
        }
        try modelContext.save()
    }

    /// pull 병합 — 레코드 단위 LWW + delete-wins tombstone (§4.4).
    func applyRemote(_ remotes: [FeedingChange]) async throws {
        guard !remotes.isEmpty else { return }
        for remote in remotes {
            let rid = remote.id
            let existing = try findModel(id: rid)

            guard let model = existing else {
                // 로컬에 없음 → 서버본 삽입 (tombstone이면 삭제 상태로 저장하되 UI 필터로 숨김).
                let m = Self.makeModel(from: remote)
                modelContext.insert(m)
                continue
            }

            // LWW: 서버 updatedAt 이 로컬보다 커야 적용. (로컬이 아직 push 안 한 최신이면 로컬 유지 → push가 이김)
            if remote.updatedAt > model.updatedAt {
                Self.overwrite(model, with: remote)
                model.syncState = .synced   // 서버본을 받아들였으니 synced
            }
            // else: 로컬이 더 최신 → 유지(dirty면 다음 push에서 서버로 전파)
        }
        try modelContext.save()
    }

    // MARK: - Private helpers

    private func findModel(id: UUID) throws -> FeedingModel? {
        let predicate = #Predicate<FeedingModel> { $0.id == id }
        var descriptor = FetchDescriptor<FeedingModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private static func toChange(_ m: FeedingModel) -> FeedingChange {
        FeedingChange(
            id: m.id, babyId: m.babyId, feedingType: m.feedingTypeRaw,
            startedAt: m.startedAt, endedAt: m.endedAt, amountMl: m.amountMl,
            durationMinutes: m.durationMinutes, memo: m.memo, didVomit: m.didVomit,
            createdAt: m.createdAt, updatedAt: m.updatedAt, deletedAt: m.deletedAt
        )
    }

    private static func makeModel(from c: FeedingChange) -> FeedingModel {
        FeedingModel(
            id: c.id, babyId: c.babyId, feedingTypeRaw: c.feedingType,
            amountMl: c.amountMl, durationMinutes: c.durationMinutes,
            startedAt: c.startedAt, endedAt: c.endedAt, memo: c.memo,
            didVomit: c.didVomit,
            createdAt: c.createdAt, updatedAt: c.updatedAt,
            syncStateRaw: SyncState.synced.rawValue, deletedAt: c.deletedAt
        )
    }

    private static func overwrite(_ m: FeedingModel, with c: FeedingChange) {
        m.babyId = c.babyId
        m.feedingTypeRaw = c.feedingType
        m.startedAt = c.startedAt
        m.endedAt = c.endedAt
        m.amountMl = c.amountMl
        m.durationMinutes = c.durationMinutes
        m.memo = c.memo
        m.didVomit = c.didVomit
        m.updatedAt = c.updatedAt
        m.deletedAt = c.deletedAt
    }
}
