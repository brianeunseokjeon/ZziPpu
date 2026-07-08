// App/SessionState.swift
// 앱 세션 라우팅 상태 — @Observable로 AppRootView가 반응

import Foundation
import Observation

/// 스플래시 → 인증 → 약관 → 온보딩 → 메인 분기를 담당하는 상태 컨테이너
@Observable
final class SessionState {

    // MARK: - Routing State

    /// Keychain 복원 완료 전 true (스플래시 표시)
    var isHydrating: Bool = true

    /// 현재 로그인 세션 (nil이면 로그인 화면)
    var session: AuthSession? = nil

    /// 활성 아기 등록 여부 (온보딩 분기용)
    var activeBabyRegistered: Bool = false

    // MARK: - Computed Routing

    var needsLogin:     Bool { session == nil }
    var needsTerms:     Bool { session?.termsRequired == true }
    var needsOnboarding: Bool { !activeBabyRegistered }

    // MARK: - Mutations

    func setSession(_ s: AuthSession?) {
        self.session = s
    }

    func markTermsAgreed() {
        session?.termsRequired = false
    }
}
