// Data/Sync/FeedingSyncEngine.swift
// feeding 양방향 동기화 엔진 (S2 push + S3 pull merge). actor 로 사이클 직렬화.
// 오케스트레이션: LocalFeedingRepository(SyncableStore) + FeedingSyncDataSource(HTTP).
// Feature 는 이 엔진의 존재를 모른다(경계 봉인).

import Foundation

actor FeedingSyncEngine {

    private let store: LocalFeedingRepository
    private let dataSource: FeedingSyncDataSource
    private let coordinator: SyncCoordinator
    private let babyIdProvider: @Sendable () -> UUID?

    // pull 커서 (도메인별) — UserDefaults 영속
    private let cursorKey = "sync.feeding.lastPulledAt"
    private var lastPulledAt: Date? {
        get {
            let t = UserDefaults.standard.double(forKey: cursorKey)
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set {
            if let d = newValue {
                UserDefaults.standard.set(d.timeIntervalSince1970, forKey: cursorKey)
            } else {
                UserDefaults.standard.removeObject(forKey: cursorKey)
            }
        }
    }

    // in-flight 코얼레싱
    private var isSyncing = false
    private var rerunRequested = false

    // 디바운스
    private var debounceTask: Task<Void, Never>?

    init(store: LocalFeedingRepository,
         dataSource: FeedingSyncDataSource,
         coordinator: SyncCoordinator,
         babyIdProvider: @escaping @Sendable () -> UUID?) {
        self.store = store
        self.dataSource = dataSource
        self.coordinator = coordinator
        self.babyIdProvider = babyIdProvider
    }

    // MARK: - Triggers (외부 진입점)

    /// 로그인 직후·포그라운드 복귀·네트워크 복구: full sync (push → pull).
    /// nonisolated: 동기 호출부(앱/네트워크 콜백)에서 await 없이 발화. 실제 작업은 Task로 액터 진입.
    nonisolated func triggerFullSync() {
        Task { await self.runCycle(pushOnly: false) }
    }

    /// 로컬 변경 후: 디바운스 후 push only (연속 입력 합침).
    nonisolated func triggerLocalChange(debounce seconds: Double = 2.0) {
        Task { await self.scheduleDebouncedPush(debounce: seconds) }
    }

    /// 로그아웃 전 best-effort push — 토큰이 유효할 때 미동기화분을 서버로 올린다(실패 무시).
    /// 로그아웃 직전에 만든 기록도 유실 없이 서버에 보존하기 위함.
    func flushPendingBestEffort() async {
        guard let babyId = babyIdProvider() else { return }
        try? await push(babyId: babyId)
    }

    /// 로컬 전량 삭제 + pull 커서 리셋(다음 로그인 때 since=nil 전량 pull).
    /// 계정 간 기록 잔존·stale 재push 오염 방지.
    func wipeAndResetCursor() async {
        debounceTask?.cancel()
        debounceTask = nil
        try? await store.deleteAllLocal()
        lastPulledAt = nil
    }

    /// 401(토큰 무효): 즉시 로컬 삭제(토큰이 없어 push 불가).
    nonisolated func resetForLogout() {
        Task { await self.wipeAndResetCursor() }
    }

    private func scheduleDebouncedPush(debounce seconds: Double) {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if Task.isCancelled { return }
            await self?.runCycle(pushOnly: true)
        }
    }

    /// 당겨서 새로고침: pull only.
    nonisolated func triggerPull() {
        Task { await self.runCycle(pushOnly: false, pullOnly: true) }
    }

    // MARK: - Cycle (직렬화 + 코얼레싱)

    private func runCycle(pushOnly: Bool, pullOnly: Bool = false) async {
        if isSyncing {
            rerunRequested = true   // 진행 중이면 끝난 뒤 한 번 더
            return
        }
        guard let babyId = babyIdProvider() else { return }

        isSyncing = true
        await coordinator.setSyncing()
        defer { Task { @MainActor in } }

        do {
            if !pullOnly {
                try await push(babyId: babyId)
            }
            if !pushOnly {
                try await pull(babyId: babyId)
            }
            await coordinator.setIdle()
        } catch let error as APIError {
            switch error {
            case .serverError, .invalidResponse:
                // 서버 다운/콜드스타트: 오프라인으로 간주. dirty는 로컬에 남아 재시도.
                await coordinator.setOffline()
            case .unauthorized:
                await coordinator.setError("인증 만료")
            default:
                await coordinator.setError("동기화 실패")
            }
        } catch {
            await coordinator.setOffline()
        }

        isSyncing = false

        // 진행 중 들어온 요청 처리
        if rerunRequested {
            rerunRequested = false
            await runCycle(pushOnly: pushOnly, pullOnly: pullOnly)
        }
    }

    // MARK: - Push (증분·멱등)

    private func push(babyId: UUID) async throws {
        let pending = try await store.pendingChanges(babyId: babyId)
        await coordinator.setPending(pending.count)
        guard !pending.isEmpty else { return }

        // 배치 200/req
        for chunk in pending.chunked(into: 200) {
            let result = try await dataSource.push(babyId: babyId, changes: chunk)
            try await store.markSynced(result.accepted)
        }
        let remaining = try await store.pendingChanges(babyId: babyId)
        await coordinator.setPending(remaining.count)
    }

    // MARK: - Pull (증분·커서·LWW)

    private func pull(babyId: UUID) async throws {
        let result = try await dataSource.pull(babyId: babyId, since: lastPulledAt)
        try await store.applyRemote(result.feedings)
        lastPulledAt = result.serverTime   // 커서 전진 (다음 since)
    }
}

// MARK: - Chunk helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
