// Feature/Auth/LoginView.swift
// 이메일 입력 화면 — 웹(login/page.tsx) 정합: 👶 이모지 로고 + 흰 카드 컨테이너.

import SwiftUI

struct LoginView: View {
    @Bindable var vm: AuthViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: theme.space.lg) {
                // 로고/타이틀 — 웹: 이모지 👶 text-5xl + "찌뿌둥" text-2xl bold + 서브 text-sm gray-500.
                VStack(spacing: theme.space.xs) {
                    Text("👶")
                        .font(.system(size: 48))
                    Text("찌뿌둥")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(theme.color.textPrimary.color)
                    Text("신생아 육아 기록")
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.color.textSecondary.color)
                }
                .padding(.top, theme.space.xl)

                // 폼 카드 — 웹: bg-white rounded-2xl shadow-sm border-gray-100 p-6.
                VStack(spacing: theme.space.md) {
                    // 이메일 라벨(Mail 아이콘) + 입력
                    VStack(alignment: .leading, spacing: theme.space.xs) {
                        Label("이메일", systemImage: "envelope")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.color.textSecondary.color)

                        DSTextField(
                            placeholder: "you@example.com",
                            text: $vm.email,
                            keyboardType: .emailAddress
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    }

                    // OTP 요청 버튼 — 웹 "인증번호 받기" blue-500.
                    DSButton(
                        "인증번호 받기",
                        size: .lg,
                        isLoading: vm.isLoading
                    ) {
                        vm.requestOtp()
                    }
                    .disabled(!vm.isEmailValid)

                    // 헬퍼 문구
                    Text("회원가입 없이 이메일 주소만으로 시작합니다.")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.textTertiary.color)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // 인라인 에러 — 웹: red-50 박스(시스템 alert 대신).
                    if let error = vm.errorMessage {
                        InlineErrorBox(message: error)
                    }
                }
                .padding(theme.space.lg)
                .dsCard()
                .padding(.horizontal, theme.space.screenPaddingX)
            }
        }
        .background(theme.color.background.color)
    }
}

// MARK: - Inline Error Box (웹 red-50 인라인 에러)

/// 웹 인증 화면의 인라인 에러 박스(text-sm red-500, bg-red-50 border-red-100).
struct InlineErrorBox: View {
    let message: String
    @Environment(\.theme) private var theme

    var body: some View {
        Text(message)
            .font(theme.typography.body)
            .foregroundStyle(theme.color.statusDangerFg.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, theme.space.stackGapMd)
            .padding(.vertical, theme.space.sm)
            .background(theme.color.statusDangerBg.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous))
    }
}

#Preview("LoginView — 라이트") {
    LoginView(vm: AuthViewModel(authRepository: AppContainer.preview.authRepository))
        .environment(\.theme, .zzippu)
}

#Preview("LoginView — 다크") {
    LoginView(vm: AuthViewModel(authRepository: AppContainer.preview.authRepository))
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
