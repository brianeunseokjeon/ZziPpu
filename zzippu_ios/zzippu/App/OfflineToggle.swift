// App/OfflineToggle.swift
// 로컬(오프라인) 저장 계층 킬 스위치 — OFFLINE_TOGGLE_PLAN §3·§4.
//
// 결정 우선순위(높은 순): 폴백 강등 플래그 > 사용자/디버그 토글 > 기본값(ON).
// 저장소: UserDefaults(런타임 토글). 재빌드 없이 끄기 가능 + 폴백과 동일 메커니즘 재사용.
//
// 제거 용이성: 이 파일 하나 삭제 + AppContainer 의 case .offline 분기 삭제로 오프라인 계층 완전 제거.

import Foundation
import SwiftData
import os

enum OfflineToggle {

    // MARK: - UserDefaults Keys

    private enum Key {
        /// 사용자/디버그가 오프라인 저장을 원하는가 (기본 true = ON).
        static let offlineEnabled = "offlineEnabled"
        /// 폴백(ModelContainer 초기화 실패)으로 강제 비활성됐는가 (다음 부팅부터 OFF 고정).
        static let offlineDisabledByFallback = "offlineDisabledByFallback"
    }

    private static let log = Logger(subsystem: "com.zzippu.app", category: "OfflineToggle")

    // MARK: - Mode

    /// 조립 모드. `.offline` 은 컨테이너 생성 성공 시에만 반환된다(연관값으로 컨테이너 전달).
    enum Mode {
        case offline(ModelContainer)
        case serverOnly
    }

    // MARK: - Flags (디버그 메뉴/폴백에서 접근)

    /// 사용자/디버그 토글 값. 미설정 시 기본 ON(true).
    static var offlineEnabled: Bool {
        get {
            let d = UserDefaults.standard
            if d.object(forKey: Key.offlineEnabled) == nil { return true } // 기본 ON
            return d.bool(forKey: Key.offlineEnabled)
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.offlineEnabled) }
    }

    /// 폴백 강등 여부(읽기 전용 노출 — 디버그 메뉴 표시용).
    static var isDisabledByFallback: Bool {
        UserDefaults.standard.bool(forKey: Key.offlineDisabledByFallback)
    }

    /// 폴백 강등 이유.
    enum FallbackReason: String {
        case initFailure // ModelContainer 초기화 실패
    }

    /// ModelContainer 초기화 실패 시 호출 — 다음 부팅부터 OFF 고정(무한 재시도 방지).
    static func markDisabledByFallback(reason: FallbackReason) {
        UserDefaults.standard.set(true, forKey: Key.offlineDisabledByFallback)
        log.error("오프라인 강등(폴백) — reason=\(reason.rawValue, privacy: .public)")
    }

    /// (디버그 전용) 폴백 강등 해제 — 다음 부팅에서 오프라인 재시도.
    /// 손상 의심 시 스토어 파일까지 지우려면 이 시점에 확장 가능(현재는 플래그만 해제).
    static func clearFallback() {
        UserDefaults.standard.set(false, forKey: Key.offlineDisabledByFallback)
    }

    // MARK: - Resolve

    /// 부팅 시 1회 호출 — 오프라인/서버-전용 결정 + 폴백 처리.
    static func resolvedMode() -> Mode {
        // 1) 폴백 강등이 걸려 있으면 무조건 server-only (사용자 토글보다 우선).
        if isDisabledByFallback {
            log.notice("오프라인 비활성(이전 폴백 강등 유지) → server-only")
            return .serverOnly
        }
        // 2) 사용자/디버그 토글 OFF → server-only.
        guard offlineEnabled else {
            log.notice("오프라인 비활성(사용자 OFF) → server-only")
            return .serverOnly
        }
        // 3) 기본 ON → ModelContainer 생성 시도. 실패 시 강등.
        do {
            let container = try AppModelContainer.makeThrowing()
            log.notice("오프라인 활성 → offline(Local+Sync)")
            return .offline(container)
        } catch {
            log.error("ModelContainer 초기화 실패 → server-only 강등: \(error.localizedDescription, privacy: .public)")
            markDisabledByFallback(reason: .initFailure)
            return .serverOnly
        }
    }
}
