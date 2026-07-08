// Domain/UseCases/RestoreSessionUseCase.swift
// 재설치 감지 + Keychain 복원 조율
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

/// 앱 첫 실행 / 재설치 감지 후 세션 복원
/// - 재설치(hasLaunchedBefore==false): Keychain 클리어 → nil 반환
/// - 기존 실행: Keychain에서 토큰 복원 → AuthSession? 반환
struct RestoreSessionUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    /// UserDefaults 키 상수
    static let hasLaunchedBeforeKey = "zzippu.hasLaunchedBefore"

    func execute() -> AuthSession? {
        let defaults = UserDefaults.standard
        let hasLaunched = defaults.bool(forKey: Self.hasLaunchedBeforeKey)

        if !hasLaunched {
            // 최초 실행 또는 재설치 — Keychain 토큰 비우기
            authRepository.signOut()
            defaults.set(true, forKey: Self.hasLaunchedBeforeKey)
            return nil
        }

        // 기존 실행 — Keychain에서 복원 (서버 검증 없음)
        return authRepository.currentSession()
    }
}
