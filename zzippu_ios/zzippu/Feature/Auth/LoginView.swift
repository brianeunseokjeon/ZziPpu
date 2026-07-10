// Feature/Auth/LoginView.swift
// 이메일 입력 화면 — 밤중·한손 조작 고려, 큼직한 입력

import SwiftUI

struct LoginView: View {
    @Bindable var vm: AuthViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 앱 로고/타이틀 영역
            VStack(spacing: theme.space.sm) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(theme.color.primary.color)

                Text("찌뿌둥")
                    .font(theme.typography.display)
                    .fontWeight(.bold)

                Text("신생아 육아 기록")
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.color.textSecondary.color)
            }
            .padding(.bottom, 56)

            // 이메일 입력
            DSTextField(
                label: "이메일",
                placeholder: "이메일 주소 입력",
                text: $vm.email,
                keyboardType: .emailAddress
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.horizontal, theme.space.lg)

            Spacer().frame(height: theme.space.xl)

            // OTP 요청 버튼
            DSButton(
                "인증코드 받기",
                isLoading: vm.isLoading
            ) {
                vm.requestOtp()
            }
            .disabled(!vm.isEmailValid)
            .padding(.horizontal, theme.space.lg)

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
