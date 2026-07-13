// Feature/Dashboard/CalendarSnapshotStore.swift
// 달력 월별 SWR 스냅샷 저장소 추상화 + 파일 구현.
// DashboardSnapshotStore 와 동일 철학: 프로토콜 추상화 → VM 옵셔널 주입.
// 제거하려면 주입만 빼면 됨(현행 메모리캐시 동작과 바이트-동일).

import Foundation

// MARK: - 추상화

protocol CalendarSnapshotStore {
    /// babyId + 월(KST) 스코프 로드. 없음/디코드 실패 → nil (크래시 금지 → 캐시 미스 처리).
    func load(babyId: UUID, month: Date) -> CalendarMonthSnapshot?
    /// 백그라운드 atomic 저장. 저장 후 아기당 월 파일 수 상한 GC.
    func save(_ snapshot: CalendarMonthSnapshot, babyId: UUID, month: Date)
    /// 로그아웃/아기 전환 시 해당 아기의 모든 월 파일 삭제.
    func clear(babyId: UUID)
}

// MARK: - 파일 구현 (Caches 디렉터리, babyId+월별 JSON)

/// Caches/calendar-{babyId}-{yyyy-MM}.json 에 월별 스냅샷 저장/복원.
/// - 캐시 위치: 시스템이 필요 시 정리 가능(사용자 데이터 아님 → 손실 무방).
/// - 디코드 실패/파일 없음 → nil (크래시 금지, SWR 캐시 미스 = 그냥 재조회).
/// - 저장은 백그라운드 큐 + atomic 쓰기 (메인스레드 블로킹 최소화).
/// - 아기당 최근 N개월(maxMonthsPerBaby)만 유지 — 초과분 오래된 순 경량 GC.
final class FileCalendarSnapshotStore: CalendarSnapshotStore {

    private let directory: URL
    private let maxMonthsPerBaby: Int
    private let ioQueue = DispatchQueue(label: "calendar.snapshot.io", qos: .utility)

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

    /// yyyy-MM 키 (KST) — 파일명 월 세그먼트.
    private let monthKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .kst
        f.dateFormat = "yyyy-MM"
        return f
    }()

    init(directory: URL? = nil, maxMonthsPerBaby: Int = 24) {
        self.directory = directory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.maxMonthsPerBaby = maxMonthsPerBaby
    }

    private func filePrefix(babyId: UUID) -> String {
        "calendar-\(babyId.uuidString)-"
    }

    private func fileURL(babyId: UUID, month: Date) -> URL {
        let key = monthKeyFormatter.string(from: month)
        return directory.appendingPathComponent("\(filePrefix(babyId: babyId))\(key).json")
    }

    /// 동기 로드 — 콜드스타트 즉시 hydrate 용(작은 JSON, 메인에서 호출해도 무해).
    func load(babyId: UUID, month: Date) -> CalendarMonthSnapshot? {
        let url = fileURL(babyId: babyId, month: month)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(CalendarMonthSnapshot.self, from: data)
    }

    /// 백그라운드 atomic 저장 — 실패해도 무시(캐시는 best-effort). 저장 후 GC.
    func save(_ snapshot: CalendarMonthSnapshot, babyId: UUID, month: Date) {
        let url = fileURL(babyId: babyId, month: month)
        guard let data = try? encoder.encode(snapshot) else { return }
        ioQueue.async { [directory, maxMonthsPerBaby] in
            try? data.write(to: url, options: .atomic)
            Self.gc(directory: directory, prefix: "calendar-\(babyId.uuidString)-", keep: maxMonthsPerBaby)
        }
    }

    /// 해당 아기의 모든 월 파일 삭제 (로그아웃/아기 전환).
    func clear(babyId: UUID) {
        let prefix = filePrefix(babyId: babyId)
        ioQueue.async { [directory] in
            let fm = FileManager.default
            guard let urls = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
            for url in urls where url.lastPathComponent.hasPrefix(prefix) {
                try? fm.removeItem(at: url)
            }
        }
    }

    // MARK: - GC (아기당 월 파일 수 상한 — 오래된 순 삭제)

    private static func gc(directory: URL, prefix: String, keep: Int) {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }

        let mine = urls.filter { $0.lastPathComponent.hasPrefix(prefix) }
        guard mine.count > keep else { return }

        // 파일명 월 키(yyyy-MM)가 문자열 정렬 = 시간 정렬 → 오래된 것이 앞.
        let sorted = mine.sorted { $0.lastPathComponent < $1.lastPathComponent }
        for url in sorted.prefix(mine.count - keep) {
            try? fm.removeItem(at: url)
        }
    }
}
