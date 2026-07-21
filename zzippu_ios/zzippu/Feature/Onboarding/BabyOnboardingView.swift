// Feature/Onboarding/BabyOnboardingView.swift
// 아기 정보 등록 — 밤중·한손 조작 고려, 큼직한 입력 UI

import SwiftUI

struct BabyOnboardingView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.theme) private var theme
    @State private var vm: OnboardingViewModel?

    var body: some View {
        Group {
            if let vm {
                OnboardingContent(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.color.background.color)
            }
        }
        .task {
            if vm == nil {
                let session = container.authRepository.currentSession()
                let newVM = OnboardingViewModel(
                    babyRepository: container.babyRepository,
                    growthRepository: container.growthRepository,
                    userId: session?.userId
                )
                let capturedContainer = container
                // onCompleted 콜백: 서버가 확정한 Baby를 받아 activeBabyId 설정
                newVM.onCompleted = { savedBaby in
                    capturedContainer.activeBabyId = savedBaby.id
                    capturedContainer.sessionState.activeBabyRegistered = true
                }
                vm = newVM
            }
        }
    }
}

// MARK: - Content

private struct OnboardingContent: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.space.lg) {
                    // 헤더 — 웹: 🍼 text-5xl + "아기 정보를 알려주세요" text-2xl bold + 서브.
                    VStack(spacing: theme.space.xs) {
                        Text("🍼")
                            .font(.system(size: 48))

                        Text("아기 정보를 알려주세요")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(theme.color.textPrimary.color)

                        Text("맞춤형 기록과 AI 피드백을 위해 필요해요.")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.color.textSecondary.color)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, theme.space.xl)

                    // 입력 폼 카드 — 웹 흰 카드(R1).
                    VStack(spacing: theme.space.lg) {
                        // 이름 — 웹 "아기 이름"(별표 없음).
                        DSTextField(
                            label: "아기 이름",
                            placeholder: "예: 우리 아기",
                            text: $vm.babyName
                        )

                        // 생년월일
                        FormField(label: "생년월일") {
                            DatePicker(
                                "",
                                selection: $vm.birthDate,
                                in: ...Date.now,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding(theme.space.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                theme.color.surface.color,
                                in: RoundedRectangle(cornerRadius: theme.radius.control)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radius.control)
                                    .stroke(theme.color.borderStrong.color, lineWidth: 1)
                            )
                        }

                        // 출생체중 (선택) — 웹 "출생 체중 (선택)".
                        FormField(
                            label: "출생 체중 (선택)",
                            note: vm.birthWeightValidation
                        ) {
                            HStack {
                                DSTextField(
                                    placeholder: "예: 3.30",
                                    text: $vm.birthWeightKgText,
                                    keyboardType: .decimalPad
                                )

                                Text("kg")
                                    .font(theme.typography.body)
                                    .foregroundStyle(theme.color.textSecondary.color)
                                    .frame(width: 32)
                            }
                        }

                        // 출생 키 (선택)
                        FormField(
                            label: "출생 키 (선택)",
                            note: vm.birthHeightValidation
                        ) {
                            HStack {
                                DSTextField(
                                    placeholder: "예: 50.0",
                                    text: $vm.birthHeightCmText,
                                    keyboardType: .decimalPad
                                )

                                Text("cm")
                                    .font(theme.typography.body)
                                    .foregroundStyle(theme.color.textSecondary.color)
                                    .frame(width: 32)
                            }
                        }

                        // 성별 — 웹: 이모지 3버튼 그리드(선택=bg-blue-50 border-blue-400 text-blue-700).
                        FormField(label: "성별") {
                            HStack(spacing: theme.space.sm) {
                                GenderButton(gender: .male,    emoji: "👦", label: "남아",   selection: $vm.gender)
                                GenderButton(gender: .female,  emoji: "👧", label: "여아",   selection: $vm.gender)
                                GenderButton(gender: .unknown, emoji: "·",  label: "비공개", selection: $vm.gender)
                            }
                        }

                        // 인라인 에러
                        if let error = vm.errorMessage {
                            InlineErrorBox(message: error)
                        }

                        // 저장 버튼 — 웹 "시작하기" blue-500.
                        DSButton(
                            "시작하기",
                            size: .lg,
                            isLoading: vm.isLoading
                        ) {
                            vm.save()
                        }
                        .disabled(!vm.isFormValid || vm.birthWeightValidation != nil || vm.birthHeightValidation != nil)
                    }
                    .padding(theme.space.lg)
                    .dsCard()
                    .padding(.horizontal, theme.space.screenPaddingX)
                    .padding(.bottom, theme.space.xl)
                }
            }
            .background(theme.color.background.color)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - GenderButton (웹 이모지 3버튼 그리드)

private struct GenderButton: View {
    let gender: Gender
    let emoji:  String
    let label:  String
    @Binding var selection: Gender
    @Environment(\.theme) private var theme

    private var isSelected: Bool { selection == gender }

    var body: some View {
        Button {
            selection = gender
        } label: {
            VStack(spacing: 2) {
                Text(emoji).font(.system(size: 18))
                Text(label)
                    .font(theme.typography.body)
                    .foregroundStyle(isSelected ? theme.color.statusInfoFg.color : theme.color.textSecondary.color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isSelected ? theme.color.primaryTint.color : theme.color.surface.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                    .stroke(isSelected ? theme.color.primary.color : theme.color.borderStrong.color,
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable Form Field

private struct FormField<Content: View>: View {
    let label: String
    var note: String? = nil
    @ViewBuilder let content: () -> Content
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(label)
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textSecondary.color)

            content()

            if let note {
                Text(note)
                    .font(theme.typography.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
