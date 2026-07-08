// Feature/Onboarding/BabyOnboardingView.swift
// 아기 정보 등록 — 밤중·한손 조작 고려, 큼직한 입력 UI

import SwiftUI

struct BabyOnboardingView: View {
    @Environment(AppContainer.self) private var container
    @State private var vm: OnboardingViewModel?

    var body: some View {
        Group {
            if let vm {
                OnboardingContent(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColor.background)
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
                newVM.onCompleted = {
                    // 등록된 아기로 activeBabyId 업데이트
                    if let baby = try? capturedContainer.babyRepository.activeBaby() {
                        capturedContainer.activeBabyId = baby.id
                    }
                    // 온보딩 완료 → 메인탭으로 분기
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // 헤더
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "figure.and.child.holdinghands")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColor.primary)

                        Text("아기 정보 등록")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)

                        Text("기록을 시작하기 위해 아기 정보를 입력해 주세요.")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.xl)

                    // 입력 폼
                    VStack(spacing: AppSpacing.lg) {
                        // 이름
                        FormField(label: "아이 이름 *") {
                            TextField("예: 준서", text: $vm.babyName)
                                .font(AppTypography.title3)
                                .padding(AppSpacing.md)
                                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
                        }

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
                            .padding(AppSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
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
                                TextField("예: 3.2", text: $vm.birthWeightKgText)
                                    .keyboardType(.decimalPad)
                                    .font(AppTypography.title3)
                                    .padding(AppSpacing.md)
                                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))

                                Text("kg")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.textSecondary)
                                    .frame(width: 32)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // 저장 버튼
                    Button(action: vm.save) {
                        Group {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("시작하기")
                                    .font(AppTypography.body)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.isFormValid || vm.birthWeightValidation != nil || vm.isLoading)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .background(AppColor.background)
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

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)

            content()

            if let note {
                Text(note)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
