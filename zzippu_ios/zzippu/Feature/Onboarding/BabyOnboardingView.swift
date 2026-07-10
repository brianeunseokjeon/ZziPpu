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
                VStack(spacing: theme.space.xl) {
                    // 헤더
                    VStack(spacing: theme.space.sm) {
                        Image(systemName: "figure.and.child.holdinghands")
                            .font(.system(size: 48))
                            .foregroundStyle(theme.color.primary.color)

                        Text("아기 정보 등록")
                            .font(theme.typography.headline)
                            .fontWeight(.bold)

                        Text("기록을 시작하기 위해 아기 정보를 입력해 주세요.")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.color.textSecondary.color)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, theme.space.xl)

                    // 입력 폼
                    VStack(spacing: theme.space.lg) {
                        // 이름
                        DSTextField(
                            label: "아이 이름 *",
                            placeholder: "예: 준서",
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
                        }

                        // 성별
                        FormField(label: "성별") {
                            Picker("성별", selection: $vm.gender) {
                                ForEach(Gender.allCases, id: \.self) { g in
                                    Text(g.displayName).tag(g)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // 출생체중 (선택)
                        FormField(
                            label: "출생체중 (선택)",
                            note: vm.birthWeightValidation
                        ) {
                            HStack {
                                DSTextField(
                                    placeholder: "예: 3.2",
                                    text: $vm.birthWeightKgText,
                                    keyboardType: .decimalPad
                                )

                                Text("kg")
                                    .font(theme.typography.body)
                                    .foregroundStyle(theme.color.textSecondary.color)
                                    .frame(width: 32)
                            }
                        }
                    }
                    .padding(.horizontal, theme.space.lg)

                    // 저장 버튼
                    DSButton(
                        "시작하기",
                        isLoading: vm.isLoading
                    ) {
                        vm.save()
                    }
                    .disabled(!vm.isFormValid || vm.birthWeightValidation != nil)
                    .padding(.horizontal, theme.space.lg)
                    .padding(.bottom, theme.space.xl)
                }
            }
            .background(theme.color.background.color)
            .navigationBarTitleDisplayMode(.inline)
        }
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
