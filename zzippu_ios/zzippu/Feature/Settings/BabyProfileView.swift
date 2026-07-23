// Feature/Settings/BabyProfileView.swift
// 아기 프로필 편집 (설정 → push). 이름/생년월일/성별/사진URL → PATCH /babies/{id}.

import SwiftUI
import PhotosUI

struct BabyProfileView: View {
    @Bindable var vm: BabyProfileViewModel
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    /// PhotosPicker 선택 항목(로드 후 로컬 저장).
    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: theme.space.lg) {

                representativeImageSection

                DSTextField(
                    label: "아이 이름 *",
                    placeholder: "예: 준서",
                    text: $vm.name
                )

                FormField(label: "생년월일·시각") {
                    DatePicker(
                        "",
                        selection: $vm.birthDate,
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.timeZone, .kst)
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
                measurementField(
                    label: "출생 체중 (선택)",
                    placeholder: "예: 3.30",
                    unit: "kg",
                    text: $vm.birthWeightKgText,
                    note: vm.birthWeightValidation
                )

                // 출생 키/두위/흉위(선택) — cm.
                measurementField(
                    label: "출생 키 (선택)",
                    placeholder: "예: 50",
                    unit: "cm",
                    text: $vm.birthHeightCmText,
                    note: vm.birthHeightValidation
                )
                measurementField(
                    label: "출생 머리둘레 (선택)",
                    placeholder: "예: 34",
                    unit: "cm",
                    text: $vm.birthHeadCircumferenceCmText,
                    note: vm.birthHeadValidation
                )
                measurementField(
                    label: "출생 가슴둘레 (선택)",
                    placeholder: "예: 33",
                    unit: "cm",
                    text: $vm.birthChestCircumferenceCmText,
                    note: vm.birthChestValidation
                )

                // 혈액형(선택) — ABO + Rh. 미선택 허용.
                FormField(label: "혈액형 (선택)") {
                    Picker("혈액형", selection: $vm.bloodType) {
                        Text("미선택").tag(BloodType?.none)
                        ForEach(BloodType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(BloodType?.some(t))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                FormField(label: "Rh 인자 (선택)") {
                    Picker("Rh 인자", selection: $vm.rhFactor) {
                        Text("미선택").tag(RhFactor?.none)
                        ForEach(RhFactor.allCases, id: \.self) { r in
                            Text(r.displayName).tag(RhFactor?.some(r))
                        }
                    }
                    .pickerStyle(.segmented)
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
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    vm.setLocalImage(image)
                }
                pickedItem = nil
            }
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

    // 대표 이미지 — 기기-로컬 저장(서버 미업로드·다중기기 공유 안 됨). 기본은 마스코트.
    private var representativeImageSection: some View {
        VStack(spacing: theme.space.sm) {
            BabyAvatar(localImage: vm.localImage, size: .lg)

            HStack(spacing: theme.space.sm) {
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Text(vm.localImage == nil ? "대표 이미지 선택" : "이미지 변경")
                        .font(theme.typography.bodyStrong)
                        .foregroundStyle(theme.color.primary.color)
                        .padding(.horizontal, theme.space.md)
                        .padding(.vertical, theme.space.sm)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                                .fill(theme.color.primaryTint.color)
                        )
                }

                if vm.localImage != nil {
                    Button("기본으로") { vm.clearLocalImage() }
                        .font(theme.typography.body)
                        .foregroundStyle(theme.color.textSecondary.color)
                        .padding(.horizontal, theme.space.md)
                        .padding(.vertical, theme.space.sm)
                }
            }

            Text("이 이미지는 이 기기에만 저장돼요 (다른 기기와 공유되지 않아요).")
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textTertiary.color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, theme.space.xs)
    }

    // 측정치 입력(decimalPad + 단위 라벨). 빈 값 허용.
    @ViewBuilder
    private func measurementField(
        label: String,
        placeholder: String,
        unit: String,
        text: Binding<String>,
        note: String?
    ) -> some View {
        FormField(label: label, note: note) {
            HStack {
                DSTextField(
                    placeholder: placeholder,
                    text: text,
                    keyboardType: .decimalPad
                )
                Text(unit)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.color.textSecondary.color)
                    .frame(width: 32)
            }
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
