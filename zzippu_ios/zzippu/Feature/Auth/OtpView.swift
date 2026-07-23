// Feature/Auth/OtpView.swift
// 6자리 OTP 입력 화면 — 웹(login/page.tsx code step) 정합: 흰 카드 + 큰 자간 입력 + 자동제출.
// 유효시간/재전송 타이머는 현행 유지(팀 결정).

import SwiftUI

struct OtpView: View {
    @Bindable var vm: AuthViewModel
    @Environment(\.theme) private var theme
    @FocusState private var otpFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: theme.space.lg) {
                // 헤더 — 전송된 이메일 표시(웹: "전송: {email}" + 이메일 변경).
                VStack(spacing: theme.space.xs) {
                    Text("인증번호 6자리")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(theme.color.textPrimary.color)
                    Text(vm.email)
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.color.textSecondary.color)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, theme.space.xl)

                VStack(spacing: theme.space.md) {
                    // 유효시간 타이머 (현행 유지)
                    VStack(spacing: theme.space.xs) {
                        Label(vm.isCodeExpired ? "만료됨" : vm.validityTimerText, systemImage: "clock")
                            .font(theme.typography.headline)
                            .monospacedDigit()
                            .foregroundStyle(
                                vm.isCodeExpired ? theme.color.statusDangerFg.color : theme.color.primary.color
                            )
                        Text(vm.isCodeExpired ? "인증번호가 만료됐어요 — 재전송해 주세요" : "인증번호 유효시간")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }

                    // OTP 입력 필드 — 웹: h-14(56) text-2xl(24) center tracking 넓게.
                    TextField("000000", text: $vm.otpCode)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .tracking(8)
                        .foregroundStyle(theme.color.textPrimary.color)
                        .focused($otpFocused)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(theme.color.surface.color)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                                .stroke(otpFocused ? theme.color.primary.color : theme.color.borderStrong.color,
                                        lineWidth: otpFocused ? 1.5 : 1)
                        )
                        .onChange(of: vm.otpCode) { _, newVal in
                            let filtered = String(newVal.filter(\.isNumber).prefix(6))
                            if filtered != newVal { vm.otpCode = filtered }
                            // 웹정합: 6자리 입력 시 자동 제출.
                            if filtered.count == 6 && !vm.isLoading {
                                vm.verifyOtp()
                            }
                        }

                    // 확인 버튼
                    DSButton(
                        "확인",
                        size: .lg,
                        isLoading: vm.isLoading
                    ) {
                        vm.verifyOtp()
                    }
                    .disabled(!vm.isOtpValid)

                    // 재전송 / 이메일 변경
                    HStack(spacing: theme.space.md) {
                        Button(vm.canResend ? "인증번호 재전송" : "\(vm.resendSeconds)초 후 재전송 가능") {
                            vm.resendOtp()
                        }
                        .font(theme.typography.body)
                        .foregroundStyle(
                            vm.canResend ? theme.color.primary.color : theme.color.textTertiary.color
                        )
                        .disabled(!vm.canResend)

                        Text("·").foregroundStyle(theme.color.textSecondary.color)

                        Button("이메일 변경") { vm.backToLogin() }
                            .font(theme.typography.body)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }

                    // 인라인 에러
                    if let error = vm.errorMessage {
                        InlineErrorBox(message: error)
                    }
                }
                .padding(theme.space.lg)
                .dsCard()
                .padding(.horizontal, theme.space.screenPaddingX)
            }
        }
        // 내용이 화면에 다 들어오면 스크롤/바운스 없음. 키보드로 가려질 땐 스크롤 허용.
        .scrollBounceBehavior(.basedOnSize)
        .background(theme.color.background.color)
        .onAppear { otpFocused = true }
    }
}

#Preview("OtpView — 라이트") {
    let vm = AuthViewModel(authRepository: AppContainer.preview.authRepository)
    vm.email = "you@example.com"
    return OtpView(vm: vm).environment(\.theme, .zzippu)
}
