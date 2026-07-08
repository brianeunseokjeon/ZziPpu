// Feature/Auth/LoginView.swift
// 이메일 입력 화면 — 밤중·한손 조작 고려, 큼직한 입력

import SwiftUI

struct LoginView: View {
    @Bindable var vm: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 앱 로고/타이틀 영역
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColor.primary)

                Text("찌뿌둥")
                    .font(AppTypography.largeTitle)
                    .fontWeight(.bold)

                Text("신생아 육아 기록")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.bottom, 56)

            // 이메일 입력
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("이메일")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)

                TextField("이메일 주소 입력", text: $vm.email)
                    .font(AppTypography.body)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(AppSpacing.md)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer().frame(height: AppSpacing.xl)

            // OTP 요청 버튼
            Button(action: vm.requestOtp) {
                Group {
                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("인증코드 받기")
                            .font(AppTypography.body)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!vm.isEmailValid || vm.isLoading)
            .padding(.horizontal, AppSpacing.lg)

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
