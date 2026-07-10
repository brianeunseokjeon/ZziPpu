// App/AppRootView.swift
// PRODUCT_SPEC §2.1 루트 분기:
//   hydrating(스플래시) → token 없음(AuthFlow) → termsRequired(약관)
//   → 서버에 baby 없음(Onboarding) → MainTabView

import SwiftUI

struct AppRootView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        let state = container.sessionState

        Group {
            if state.isHydrating {
                // ① 스플래시 — Keychain 복원 + GET /babies 완료 전 (깜빡임 방지)
                SplashView()
            } else if state.needsLogin {
                // ② 로그인 화면
                AuthFlowView()
                    .environment(container)
            } else if state.needsTerms {
                // ③ 약관 동의 (termsRequired=true)
                TermsAgreementView()
                    .environment(container)
            } else if state.babyLoadFailed {
                // ③-b 아기 목록 조회 실패 → 온보딩으로 오인하지 않고 재시도
                BabyLoadErrorView { await loadBabies() }
            } else if state.needsOnboarding {
                // ④ 아기 온보딩 — 서버에 아기 없는 신규 사용자
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

    // MARK: - Session Hydration (S2 핵심: GET /babies로 기존 데이터 확인)

    /// 1. Keychain 복원(동기)
    /// 2. 로그인 상태면 GET /babies 호출 → 결과 유무로 온보딩 여부 결정
    /// 3. 첫 아기 id를 activeBabyId에 세팅
    /// → essy1224 등 기존 계정은 온보딩 없이 홈으로 바로 진입
    @MainActor
    private func hydrateSession() async {
        let useCase = RestoreSessionUseCase(authRepository: container.authRepository)
        let session = useCase.execute()   // 동기 (Keychain I/O만)

        container.sessionState.setSession(session)

        // 로그인된 경우에만 서버에서 아기 목록 조회
        if session != nil {
            await loadBabies()
        }

        // 마지막에 isHydrating 해제 (스플래시 → 실제 화면)
        container.sessionState.isHydrating = false
    }

    /// 서버에서 아기 목록을 조회해 라우팅 상태를 갱신한다.
    /// - 성공: activeBabyRegistered = 목록 유무 (빈 목록이면 온보딩)
    /// - 실패: babyLoadFailed = true (온보딩 아닌 재시도 화면). 온보딩 오인으로 인한 중복 생성 방지.
    @MainActor
    private func loadBabies() async {
        do {
            let babies = try await container.babyRepository.fetchAll()
            container.sessionState.activeBabyRegistered = !babies.isEmpty
            container.sessionState.babyLoadFailed = false
            if let first = babies.first {
                container.activeBabyId = first.id
            }
        } catch {
            container.sessionState.babyLoadFailed = true
        }
    }
}

// MARK: - Baby Load Error View

/// 아기 목록 조회 실패 시 재시도 화면 (온보딩으로 잘못 빠지지 않게)
private struct BabyLoadErrorView: View {
    let retry: () async -> Void
    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(AppColor.textSecondary)
            Text("데이터를 불러오지 못했어요")
                .font(AppTypography.headline)
            Text("잠시 후 다시 시도해 주세요.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            Button {
                Task {
                    isRetrying = true
                    await retry()
                    isRetrying = false
                }
            } label: {
                if isRetrying {
                    ProgressView().tint(.white)
                } else {
                    Text("다시 시도").fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRetrying)
            .padding(.top, AppSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
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
                let capturedContainer = container
                authVM.onSessionRestored = { session in
                    capturedContainer.sessionState.setSession(session)
                    // 로그인 직후 서버에서 아기 목록 조회
                    Task { @MainActor in
                        do {
                            let babies = try await capturedContainer.babyRepository.fetchAll()
                            capturedContainer.sessionState.activeBabyRegistered = !babies.isEmpty
                            capturedContainer.sessionState.babyLoadFailed = false
                            if let first = babies.first {
                                capturedContainer.activeBabyId = first.id
                            }
                        } catch {
                            capturedContainer.sessionState.babyLoadFailed = true
                        }
                    }
                }
                vm = authVM
            }
        }
    }
}
