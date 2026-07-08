// App/AppRootView.swift
// PRODUCT_SPEC §2.1 루트 분기:
//   hydrating(스플래시) → token 없음(AuthFlow) → termsRequired(약관)
//   → 활성 baby 없음(Onboarding) → MainTabView

import SwiftUI

struct AppRootView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        let state = container.sessionState

        Group {
            if state.isHydrating {
                // ① 스플래시 — Keychain 복원 완료 전 (깜빡임 방지)
                SplashView()
            } else if state.needsLogin {
                // ② 로그인 화면
                AuthFlowView()
                    .environment(container)
            } else if state.needsTerms {
                // ③ 약관 동의 (termsRequired=true)
                TermsAgreementView()
                    .environment(container)
            } else if state.needsOnboarding {
                // ④ 아기 온보딩 (처음 사용자)
                BabyOnboardingView()
                    .environment(container)
            } else {
                // ⑤ 메인 탭
                MainTabView()
                    .environment(container)
            }
        }
        .task {
            await hydrateSession()
        }
    }

    // MARK: - Session Hydration

    /// 재설치 감지 + Keychain 복원
    /// - 서버 검증 없음(런타임 401에서만 감지)
    /// - 복원 완료 후 isHydrating = false → 라우팅 확정
    @MainActor
    private func hydrateSession() async {
        let useCase = RestoreSessionUseCase(authRepository: container.authRepository)
        let session = useCase.execute()   // 동기 (Keychain I/O만)

        // 활성 아기 여부 확인
        let hasActiveBaby = (try? container.babyRepository.activeBaby()) != nil

        container.sessionState.setSession(session)
        container.sessionState.activeBabyRegistered = hasActiveBaby

        if let baby = try? container.babyRepository.activeBaby() {
            container.activeBabyId = baby.id
        }

        // 마지막에 isHydrating 해제 (스플래시 → 실제 화면)
        container.sessionState.isHydrating = false
    }
}

// MARK: - Splash View

private struct SplashView: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 72))
                .foregroundStyle(AppColor.primary)
            Text("찌뿌둥")
                .font(AppTypography.largeTitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
    }
}

// MARK: - Auth Flow

/// 로그인 흐름 컨테이너 (LoginView ↔ OtpView 전환 + onSessionRestored 처리)
private struct AuthFlowView: View {
    @Environment(AppContainer.self) private var container
    @State private var vm: AuthViewModel?

    var body: some View {
        Group {
            if let vm {
                NavigationStack {
                    switch vm.step {
                    case .login:
                        LoginView(vm: vm)
                            .toolbar(.hidden, for: .navigationBar)
                    case .otp:
                        OtpView(vm: vm)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColor.background)
            }
        }
        .task {
            if vm == nil {
                let authVM = AuthViewModel(authRepository: container.authRepository)
                // container는 @Observable class — 강한 참조로 캡처 (SwiftUI가 생명주기 관리)
                let capturedContainer = container
                authVM.onSessionRestored = { session in
                    capturedContainer.sessionState.setSession(session)
                    let hasActiveBaby = (try? capturedContainer.babyRepository.activeBaby()) != nil
                    capturedContainer.sessionState.activeBabyRegistered = hasActiveBaby
                }
                vm = authVM
            }
        }
    }
}
