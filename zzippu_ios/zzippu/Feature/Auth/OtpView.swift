// Feature/Auth/OtpView.swift
// 6자리 OTP 입력 화면

import SwiftUI

struct OtpView: View {
    @Bindable var vm: AuthViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 헤더
            VStack(spacing: theme.space.sm) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.color.primary.color)

                Text("인증코드 확인")
                    .font(theme.typography.title)

                Text(vm.email)
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.color.textSecondary.color)

                Text("로 6자리 인증코드를 보냈어요.")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, theme.space.lg)

            // 인증코드 유효시간 타이머 (5:00 → 0, 명시적 표시)
            VStack(spacing: theme.space.xs) {
                Label(vm.isCodeExpired ? "만료됨" : vm.validityTimerText, systemImage: "clock")
                    .font(theme.typography.title)
                    .monospacedDigit()
                    .foregroundStyle(
                        vm.isCodeExpired ? theme.color.statusDangerFg.color : theme.color.primary.color
                    )
                Text(vm.isCodeExpired ? "인증코드가 만료됐어요 — 재전송해 주세요" : "인증코드 유효시간")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
            }
            .padding(.bottom, theme.space.lg)

            // OTP 입력 필드
            DSTextField(
                label: "인증코드 (6자리)",
                placeholder: "000000",
                text: $vm.otpCode,
                keyboardType: .numberPad
            )
            .onChange(of: vm.otpCode) { _, newVal in
                // 최대 6자리 제한
                if newVal.count > 6 {
                    vm.otpCode = String(newVal.prefix(6))
                }
                // 숫자만 허용
                vm.otpCode = newVal.filter(\.isNumber)
            }
            .padding(.horizontal, theme.space.lg)

            Spacer().frame(height: theme.space.xl)

            // 확인 버튼
            DSButton(
                "확인",
                isLoading: vm.isLoading
            ) {
                vm.verifyOtp()
            }
            .disabled(!vm.isOtpValid)
            .padding(.horizontal, theme.space.lg)

            // 재전송 / 뒤로
            HStack(spacing: theme.space.md) {
                Button(vm.canResend ? "코드 재전송" : "\(vm.resendSeconds)초 후 재전송") {
                    vm.resendOtp()
                }
                .font(theme.typography.caption)
                .foregroundStyle(
                    vm.canResend ? theme.color.primary.color : theme.color.textTertiary.color
                )
                .disabled(!vm.canResend)

                Text("·")
                    .foregroundStyle(theme.color.textSecondary.color)

                Button("이메일 변경") { vm.backToLogin() }
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textSecondary.color)
            }
            .padding(.top, theme.space.md)

            Spacer()
        }
        .background(theme.color.background.color)
        .alert("오류", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
