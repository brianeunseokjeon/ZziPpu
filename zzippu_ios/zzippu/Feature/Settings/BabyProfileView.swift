// Feature/Settings/BabyProfileView.swift
// 아기 프로필 편집 (설정 → push). 이름/생년월일/성별/사진URL → PATCH /babies/{id}.

import SwiftUI

struct BabyProfileView: View {
    @Bindable var vm: BabyProfileViewModel
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: theme.space.lg) {
                DSTextField(
                    label: "아이 이름 *",
                    placeholder: "예: 준서",
                    text: $vm.name
                )

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

                FormField(label: "성별") {
                    Picker("성별", selection: $vm.gender) {
                        ForEach(Gender.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 출생 체중(선택) — 태어날 때 고정값. kg 입력 → g 저장.
                FormField(label: "출생 체중 (선택)", note: vm.birthWeightValidation) {
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

                DSTextField(
                    label: "사진 URL (선택)",
                    placeholder: "https://...",
                    text: $vm.photoUrlText,
                    keyboardType: .URL
                )

                DSButton("저장", isLoading: vm.isSaving) {
                    vm.save()
                }
                .disabled(!vm.isFormValid)
                .padding(.top, theme.space.sm)
            }
            .padding(.horizontal, theme.space.lg)
            .padding(.vertical, theme.space.lg)
        }
        .background(theme.color.background.color)
        .navigationTitle("아기 프로필")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: vm.didSave) { _, saved in
            if saved { dismiss() }
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
                    .foregroundStyle(theme.color.statusDangerFg.color)
            }
        }
    }
}

// MARK: - Preview

#Preview("BabyProfileView — 라이트") {
    NavigationStack {
        BabyProfileView(vm: BabyProfileViewModel(
            baby: Baby.new(name: "준서", birthDate: .now, gender: .male),
            babyRepository: AppContainer.preview.babyRepository
        ))
    }
    .environment(\.theme, .zzippu)
}

#Preview("BabyProfileView — 다크") {
    NavigationStack {
        BabyProfileView(vm: BabyProfileViewModel(
            baby: Baby.new(name: "준서", birthDate: .now, gender: .female),
            babyRepository: AppContainer.preview.babyRepository
        ))
    }
    .environment(\.theme, .zzippu)
    .preferredColorScheme(.dark)
}
