// Feature/Home/QuickBarSettings.swift
// 홈 빠른기록 바 표시/순서 영속 저장소.
// OfflineToggle 패턴(enum 네임스페이스 + computed property).
// key: "quickbar.visibleKinds" = JSON String 배열(순서=화면순서, 숨김=배열에 없음).

import Foundation
import os

enum QuickBarSettings {

    // MARK: - Key

    private static let key = "quickbar.visibleKinds"
    /// 사용자가 이미 "본" kind 집합 — 숨김과 신규를 구분하기 위함(숨김은 known에 남아 재노출 안 됨).
    private static let knownKey = "quickbar.knownKinds"
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

    // MARK: - known kinds (숨김 vs 신규 구분용)

    /// 사용자가 이미 본 kind 집합. 미설정(최초)이면 현재 카탈로그 전체를 "이미 앎"으로 간주
    /// → 기존 사용자가 하나 숨긴 상태여도 그 숨김이 존중된다.
    private static func loadKnown() -> Set<QuickButtonKind> {
        guard let s = UserDefaults.standard.string(forKey: knownKey),
              let d = s.data(using: .utf8),
              let raw = try? JSONDecoder().decode([String].self, from: d)
        else {
            return Set(defaultKinds)
        }
        return Set(raw.compactMap { QuickButtonKind(rawValue: $0) })
    }

    private static func saveKnown(_ kinds: Set<QuickButtonKind>) {
        let raw = kinds.map(\.rawValue)
        if let d = try? JSONEncoder().encode(raw), let s = String(data: d, encoding: .utf8) {
            UserDefaults.standard.set(s, forKey: knownKey)
        }
    }

    // MARK: - 마이그레이션

    /// 앱 업데이트로 **처음 등장한(사용자가 본 적 없는)** kind만 표시 목록 끝에 append.
    /// 사용자가 의도적으로 숨긴 kind는 known에 남아있어 재노출되지 않는다(숨김 존중).
    /// 폐기 kind는 loadRaw()의 compactMap에서 이미 드롭됨.
    private static func migrate(_ current: [QuickButtonKind]) -> [QuickButtonKind] {
        let known = loadKnown()
        let newKinds = defaultKinds.filter { !known.contains($0) }   // 진짜 신규만
        // known을 현재 카탈로그까지 확장·영속(다음부터 "본 것"으로 취급)
        saveKnown(known.union(defaultKinds))

        guard !newKinds.isEmpty else { return current }
        let migrated = current + newKinds
        saveRaw(migrated)
        log.notice("QuickBarSettings 마이그레이션: 신규 kind \(newKinds.map(\.rawValue), privacy: .public) append")
        return migrated
    }
}
