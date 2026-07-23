// App/AppRootView.swift
// PRODUCT_SPEC §2.1 루트 분기:
//   hydrating(스플래시) → token 없음(AuthFlow) → termsRequired(약관)
//   → 서버에 baby 없음(Onboarding) → MainTabView

import SwiftUI

struct AppRootView: View {
    @Environment(AppContainer.self) private var container

    // 앱 공용 내비게이션 상태 — 탭 가로질러 딥링크(대시보드 성장 카드 → 발달 성장 세그먼트).
    @State private var appNav = AppNavigationState()

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
                    .environment(appNav)
            }
        }
        .dsTypeCap()   // 고정 pt 위 접근성 상한(...xLarge) — 웹 레이아웃 유지 + 신생아 아빠 배려
        .task {
            await hydrateSession()
        }
        // 서버 401(토큰 무효) → 메인에서 로그아웃 + 로그인 화면으로 라우팅.
        .onReceive(NotificationCenter.default.publisher(for: .zzippuUnauthorized)) { _ in
            container.handleUnauthorized()
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
                // 무회귀 보장: 로그인/활성아기 확정 직후 초기 동기화(첫 pull로 서버 feeding을 로컬에 채움).
                container.triggerFeedingFullSync()
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
    @Environment(\.theme) private var theme

    var body: some View {
        DSEmptyState(
            icon: "wifi.exclamationmark",
            message: "데이터를 불러오지 못했어요\n잠시 후 다시 시도해 주세요.",
            actionLabel: "다시 시도",
            actionLoading: isRetrying     // 라벨 바꿔치기 대신 로딩 상태 → 버튼 폭 유지
        ) {
            Task {
                isRetrying = true
                await retry()
                isRetrying = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.color.background.color)
    }
}

// MARK: - Splash View

private struct SplashView: View {
    @Environment(\.theme) private var theme

    // 서로 다른 주기의 모션을 겹쳐 "몽글몽글/말캉말캉" 유기적 느낌을 낸다(이미지 변경 없음).
    @State private var breathe = false   // 숨쉬듯 전체 크기
    @State private var squish  = false   // 젤리 스쿼시(가로↔세로)
    @State private var float   = false   // 위아래 부유(구름)
    @State private var sway    = false   // 살짝 갸웃

    var body: some View {
        ZStack {
            theme.color.background.color.ignoresSafeArea()

            // 마스코트 (중앙, 몽글몽글 애니메이션)
            Image("Mascot")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                // 겹쳐지는 변형: 균등 숨쉬기 + 젤리(비균등) + 회전 + 부유
                .scaleEffect(breathe ? 1.04 : 0.97)
                .scaleEffect(x: squish ? 1.05 : 0.96, y: squish ? 0.96 : 1.05, anchor: .bottom)
                .rotationEffect(.degrees(sway ? 3.5 : -3.5))
                .offset(y: float ? -10 : 8)
                // 구름같은 말랑한 그림자(같이 호흡)
                .shadow(color: theme.color.primary.color.opacity(0.18),
                        radius: breathe ? 28 : 14, y: float ? 12 : 4)

            // 하단 브랜드·저작권 (Meta/Instagram 스플래시 스타일)
            VStack {
                Spacer()
                VStack(spacing: 3) {
                    Text("찌뿌둥")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.color.textSecondary.color)
                    Text("© 2026 zzippu")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textTertiary.color)
                }
                .padding(.bottom, theme.space.xl)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) { squish  = true }
            withAnimation(.easeInOut(duration: 1.85).repeatForever(autoreverses: true)) { float   = true }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true))  { sway    = true }
        }
    }
}

// MARK: - Auth Flow

/// 로그인 흐름 컨테이너 (LoginView ↔ OtpView 전환 + onSessionRestored 처리)
private struct AuthFlowView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.theme) private var theme
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
                    .background(theme.color.background.color)
            }
        }
        .task {
            if vm == nil {
                let authVM = AuthViewModel(authRepository: container.authRepository)
                let capturedContainer = container
                authVM.onSessionRestored = { session in
                    capturedContainer.sessionState.setSession(session)
                    // 아기 조회 중엔 스플래시 유지 → 온보딩 화면이 잠깐 깜빡이는 것 방지.
                    // (조회 완료 후에만 온보딩/홈 분기 확정)
                    capturedContainer.sessionState.isHydrating = true
                    Task { @MainActor in
                        do {
                            let babies = try await capturedContainer.babyRepository.fetchAll()
                            capturedContainer.sessionState.activeBabyRegistered = !babies.isEmpty
                            capturedContainer.sessionState.babyLoadFailed = false
                            if let first = babies.first {
                                capturedContainer.activeBabyId = first.id
                                capturedContainer.triggerFeedingFullSync()
                            }
                        } catch {
                            capturedContainer.sessionState.babyLoadFailed = true
                        }
                        capturedContainer.sessionState.isHydrating = false
                    }
                }
                vm = authVM
            }
        }
    }
}
