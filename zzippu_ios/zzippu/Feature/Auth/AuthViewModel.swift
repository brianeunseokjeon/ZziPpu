// Feature/Auth/AuthViewModel.swift
// @Observable — Domain 프로토콜(AuthRepository)만 의존. Data 구현체 몰라도 됨.

import Foundation
import Observation

@Observable
final class AuthViewModel {

    // MARK: - State

    enum Step {
        case login          // 이메일 입력
        case otp            // OTP 6자리 입력
    }

    var step: Step = .login
    var email: String = ""
    var otpCode: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil

    /// 인증코드 유효시간 남은 초 (300 → 0). 서버 TTL(5분)과 일치.
    var validitySeconds: Int = 0
    /// 재전송 쿨다운 남은 초 (60 → 0). 0이면 재전송 가능. 서버 쿨다운(60초)과 일치.
    var resendSeconds: Int = 0

    private let codeValidity = 300   // 코드 유효시간 5분
    private let resendCooldown = 60  // 재전송 쿨다운 60초

    // MARK: - Dependencies

    private let authRepository: AuthRepository
    private var countdownTask: Task<Void, Never>?

    /// 로그인 성공 시 App 레이어에 세션 전달 (AppRootView 업데이트 트리거)
    var onSessionRestored: ((AuthSession) -> Void)?

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    deinit { countdownTask?.cancel() }

    // MARK: - Actions

    /// 이메일로 OTP 발송 요청
    func requestOtp() {
        guard isValidEmail(email) else {
            errorMessage = "올바른 이메일 주소를 입력해 주세요."
            return
        }
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                try await authRepository.requestEmailOtp(email: email)
                step = .otp
                startCountdowns()   // 발송 성공 → 유효시간(5분)·재전송쿨다운(60초) 시작
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// OTP 검증 → 로그인 완료
    func verifyOtp() {
        guard otpCode.count == 6 else {
            errorMessage = "6자리 인증코드를 입력해 주세요."
            return
        }
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                let session = try await authRepository.verifyEmailOtp(email: email, code: otpCode)
                countdownTask?.cancel()
                onSessionRestored?(session)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// OTP 재전송 — 쿨다운(60초) 중엔 무시. 성공 시 타이머 재시작.
    func resendOtp() {
        guard canResend else { return }
        otpCode = ""
        requestOtp()
    }

    /// 이메일 입력 단계로 되돌아가기
    func backToLogin() {
        step = .login
        otpCode = ""
        errorMessage = nil
        countdownTask?.cancel()
        validitySeconds = 0
        resendSeconds = 0
    }

    // MARK: - Countdown

    /// 유효시간(300초)·재전송쿨다운(60초)을 매초 함께 감소.
    private func startCountdowns() {
        countdownTask?.cancel()
        validitySeconds = codeValidity
        resendSeconds = resendCooldown
        countdownTask = Task { @MainActor [weak self] in
            while let self, (self.validitySeconds > 0 || self.resendSeconds > 0) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                if self.validitySeconds > 0 { self.validitySeconds -= 1 }
                if self.resendSeconds > 0 { self.resendSeconds -= 1 }
            }
        }
    }

    // MARK: - Computed

    var isEmailValid: Bool { isValidEmail(email) }
    var isOtpValid:   Bool { otpCode.count == 6 }

    /// 재전송 가능 여부 (쿨다운 종료 + 비로딩)
    var canResend: Bool { resendSeconds <= 0 && !isLoading }

    /// 코드 만료 여부 (유효시간 소진)
    var isCodeExpired: Bool { validitySeconds <= 0 }

    /// 유효시간 "M:SS" (예: 4:47)
    var validityTimerText: String {
        let m = validitySeconds / 60
        let s = validitySeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Private

    private func isValidEmail(_ s: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }
}
