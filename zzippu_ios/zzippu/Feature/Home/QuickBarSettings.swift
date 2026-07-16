// Feature/Home/QuickBarSettings.swift
// 홈 빠른기록 바 표시/순서 영속 저장소.
// OfflineToggle 패턴(enum 네임스페이스 + computed property).
// key: "quickbar.visibleKinds" = JSON String 배열(순서=화면순서, 숨김=배열에 없음).

import Foundation
import os

enum QuickBarSettings {

    // MARK: - Key

    private static let key = "quickbar.visibleKinds"
    private static let log = Logger(subsystem: "com.zzippu.app", category: "QuickBarSettings")

    // MARK: - 기본값

    /// 기본값 = 카탈로그 전체 순서.
    static var defaultKinds: [QuickButtonKind] {
        QuickActionCatalog.all.map(\.kind)
    }

    // MARK: - get / set

    /// 표시 목록 로드. 디코드 실패 시 기본값 폴백 + 마이그레이션(신규 append / 폐기 드롭) 자동 처리.
    static var visibleKinds: [QuickButtonKind] {
        get {
            let loaded = loadRaw()
            let migrated = migrate(loaded)
            return migrated
        }
        set {
            // 최소 1개 보장
            let safe = newValue.isEmpty ? defaultKinds : newValue
            saveRaw(safe)
        }
    }

    // MARK: - 기본값 복원

    static func resetToDefault() {
        saveRaw(defaultKinds)
    }

    // MARK: - 내부 로드/저장

    private static func loadRaw() -> [QuickButtonKind] {
        guard let jsonString = UserDefaults.standard.string(forKey: key),
              let data = jsonString.data(using: .utf8),
              let rawArray = try? JSONDecoder().decode([String].self, from: data)
        else {
            // 키 미설정 또는 디코드 실패 → 기본값
            return defaultKinds
        }
        // rawValue → QuickButtonKind 변환 (카탈로그에 없는 rawValue = 폐기 드롭)
        return rawArray.compactMap { QuickButtonKind(rawValue: $0) }
    }

    private static func saveRaw(_ kinds: [QuickButtonKind]) {
        let rawArray = kinds.map(\.rawValue)
        guard let data = try? JSONEncoder().encode(rawArray),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            log.error("QuickBarSettings: 저장 실패 (JSON 인코드 오류)")
            return
        }
        UserDefaults.standard.set(jsonString, forKey: key)
    }

    // MARK: - 마이그레이션

    /// 앱 업데이트로 신규 kind가 카탈로그에 추가된 경우:
    ///   - 저장값에 없는 kind → 표시 목록 끝에 append (의도적 숨김이 아닌 "당시 없던 것"이므로 노출 안전).
    /// 카탈로그에서 사라진 kind(폐기):
    ///   - loadRaw()에서 이미 compactMap으로 드롭됨.
    /// 변경이 있으면 즉시 저장(1회성 정규화).
    private static func migrate(_ current: [QuickButtonKind]) -> [QuickButtonKind] {
        let catalogKinds = defaultKinds
        let missing = catalogKinds.filter { !current.contains($0) }
        if missing.isEmpty { return current }

        let migrated = current + missing
        saveRaw(migrated)
        log.notice("QuickBarSettings 마이그레이션: 신규 kind \(missing.map(\.rawValue), privacy: .public) append")
        return migrated
    }
}
