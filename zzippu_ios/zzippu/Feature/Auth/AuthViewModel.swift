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

    // MARK: - Dependencies

    private let authRepository: AuthRepository

    /// 로그인 성공 시 App 레이어에 세션 전달 (AppRootView 업데이트 트리거)
    var onSessionRestored: ((AuthSession) -> Void)?

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

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
                onSessionRestored?(session)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// OTP 재전송 (step 유지, 코드 초기화)
    func resendOtp() {
        otpCode = ""
        requestOtp()
    }

    /// 이메일 입력 단계로 되돌아가기
    func backToLogin() {
        step = .login
        otpCode = ""
        errorMessage = nil
    }

    // MARK: - Computed

    var isEmailValid: Bool { isValidEmail(email) }
    var isOtpValid:   Bool { otpCode.count == 6 }

    // MARK: - Private

    private func isValidEmail(_ s: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }
}
