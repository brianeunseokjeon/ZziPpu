// Feature/Dashboard/DashboardSnapshotStore.swift
// 대시보드 SWR 스냅샷 저장소 추상화 + 파일 구현.
// 결합도↓: 프로토콜로 추상화 → VM에는 옵셔널 주입. 제거하려면 주입만 빼면 됨.

import Foundation

// MARK: - 추상화

protocol DashboardSnapshotStore {
    func load(babyId: UUID) -> DashboardSnapshot?
    func save(_ snapshot: DashboardSnapshot, babyId: UUID)
}

// MARK: - 파일 구현 (Caches 디렉터리, babyId별 JSON)

/// Caches/dashboard-{babyId}.json 에 스냅샷을 저장/복원.
/// - 캐시 위치: 시스템이 필요 시 정리 가능(사용자 데이터 아님 → 손실 무방).
/// - 디코드 실패/파일 없음 → nil (크래시 금지, SWR 캐시 미스 = 그냥 서버 fetch).
/// - 저장은 백그라운드 큐 + atomic 쓰기 (메인스레드 블로킹 최소화).
final class FileDashboardSnapshotStore: DashboardSnapshotStore {

    private let directory: URL
    private let ioQueue = DispatchQueue(label: "dashboard.snapshot.io", qos: .utility)

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601   // 날짜 일관 전략
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(directory: URL? = nil) {
        self.directory = directory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func fileURL(babyId: UUID) -> URL {
        directory.appendingPathComponent("dashboard-\(babyId.uuidString).json")
    }

    /// 동기 로드 — 콜드스타트 즉시 hydrate 용(작은 JSON, 메인에서 호출해도 무해).
    func load(babyId: UUID) -> DashboardSnapshot? {
        let url = fileURL(babyId: babyId)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(DashboardSnapshot.self, from: data)
    }

    /// 백그라운드 atomic 저장 — 실패해도 무시(캐시는 best-effort).
    func save(_ snapshot: DashboardSnapshot, babyId: UUID) {
        let url = fileURL(babyId: babyId)
        guard let data = try? encoder.encode(snapshot) else { return }
        ioQueue.async {
            try? data.write(to: url, options: .atomic)
        }
    }
}
