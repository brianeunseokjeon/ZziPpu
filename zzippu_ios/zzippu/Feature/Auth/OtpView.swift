// Feature/Auth/OtpView.swift
// 6자리 OTP 입력 화면

import SwiftUI

struct OtpView: View {
    @Bindable var vm: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 헤더
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColor.primary)

                Text("인증코드 확인")
                    .font(AppTypography.title2)
                    .fontWeight(.bold)

                Text(vm.email)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)

                Text("로 6자리 인증코드를 보냈어요.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 48)

            // OTP 입력 필드
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("인증코드 (6자리)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)

                TextField("000000", text: $vm.otpCode)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .tracking(8)
                    .onChange(of: vm.otpCode) { _, newVal in
                        // 최대 6자리 제한
                        if newVal.count > 6 {
                            vm.otpCode = String(newVal.prefix(6))
                        }
                        // 숫자만 허용
                        vm.otpCode = newVal.filter(\.isNumber)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer().frame(height: AppSpacing.xl)

            // 확인 버튼
            Button(action: vm.verifyOtp) {
                Group {
                    if vm.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("확인")
                            .font(AppTypography.body)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!vm.isOtpValid || vm.isLoading)
            .padding(.horizontal, AppSpacing.lg)

            // 재전송 / 뒤로
            HStack(spacing: AppSpacing.md) {
                Button("코드 재전송") { vm.resendOtp() }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.primary)
                    .disabled(vm.isLoading)

                Text("·")
                    .foregroundStyle(AppColor.textSecondary)

                Button("이메일 변경") { vm.backToLogin() }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.top, AppSpacing.md)

            Spacer()
        }
        .background(AppColor.background)
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
