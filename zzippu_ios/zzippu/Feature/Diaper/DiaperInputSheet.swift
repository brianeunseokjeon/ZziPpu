// Feature/Diaper/DiaperInputSheet.swift
// 기저귀 입력 바텀시트.

import SwiftUI

struct DiaperInputSheet: View {
    @Environment(AppContainer.self) private var container
    @State private var vm: DiaperViewModel?
    @Binding var isPresented: Bool
    var onSaved: ((DiaperRecord) -> Void)? = nil

    var body: some View {
        Group {
            if let vm {
                DiaperInputContent(
                    vm: vm,
                    isPresented: $isPresented,
                    onSaved: onSaved
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if vm == nil {
                vm = DiaperViewModel(
                    repository: container.diaperRepository,
                    babyId: container.activeBabyId
                )
            }
        }
    }
}

// MARK: - Content

private struct DiaperInputContent: View {
    @Bindable var vm: DiaperViewModel
    @Binding var isPresented: Bool
    let onSaved: ((DiaperRecord) -> Void)?

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.space.md) {
                    // 기저귀 종류 선택
                    VStack(alignment: .leading, spacing: theme.space.xs) {
                        Text("종류")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)
                        HStack(spacing: theme.space.sm) {
                            ForEach(DiaperType.allCases, id: \.self) { type in
                                DSChip(
                                    label: type.displayName,
                                    isSelected: vm.selectedType == type,
                                    variant: .selectable,
                                    onTap: { vm.selectedType = type }
                                )
                            }
                            Spacer()
                        }
                    }

                    // 대변 색 (대변/소변+대변 선택 시)
                    if vm.selectedType.hasPoo {
                        VStack(alignment: .leading, spacing: theme.space.xs) {
                            Text("대변 색")
                                .font(theme.typography.captionStrong)
                                .foregroundStyle(theme.color.textSecondary.color)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.space.sm) {
                                    ForEach(StoolColor.allCases, id: \.self) { color in
                                        DSChip(
                                            label: color.displayName,
                                            isSelected: vm.selectedColor == color,
                                            variant: .selectable,
                                            tint: theme.color.swatch(for: color.stoolSwatch),
                                            onTap: {
                                                vm.selectedColor = vm.selectedColor == color ? nil : color
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }

                        // 대변 상태
                        VStack(alignment: .leading, spacing: theme.space.xs) {
                            Text("대변 상태")
                                .font(theme.typography.captionStrong)
                                .foregroundStyle(theme.color.textSecondary.color)
                            HStack(spacing: theme.space.sm) {
                                ForEach(StoolState.allCases, id: \.self) { state in
                                    DSChip(
                                        label: state.displayName,
                                        isSelected: vm.selectedState == state,
                                        variant: .selectable,
                                        onTap: {
                                            vm.selectedState = vm.selectedState == state ? nil : state
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // 기록 시각
                    VStack(alignment: .leading, spacing: theme.space.xs) {
                        Text("기록 시각")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)
                        DatePicker(
                            "",
                            selection: $vm.recordedAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                    }
                }
                .padding(.horizontal, theme.space.screenPaddingX)
                .padding(.vertical, theme.space.md)
            }

            DSButton("저장", variant: .primary, size: .lg) {
                handleSave()
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.bottom, theme.space.md)
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

    private func handleSave() {
        let diaper = DiaperRecord.new(
            babyId: vm.babyId,
            diaperType: vm.selectedType,
            recordedAt: vm.recordedAt,
            stoolColor: vm.selectedType.hasPoo ? vm.selectedColor : nil,
            stoolState: vm.selectedType.hasPoo ? vm.selectedState : nil,
            memo: vm.memo.isEmpty ? nil : vm.memo
        )
        vm.resetInputs()
        isPresented = false
        if let onSaved {
            onSaved(diaper)
        } else {
            vm.saveDiaper()
        }
    }
}

// MARK: - Preview

private struct DiaperInputSheetPreview: View {
    @State private var show = true
    let container = AppContainer()
    let dark: Bool
    var body: some View {
        Color.clear
            .dsBottomSheet(isPresented: $show, options: .init(title: "기저귀 기록", detents: [.medium, .large])) {
                DiaperInputSheet(isPresented: $show).environment(container)
            }
            .environment(\.theme, .zzippu)
            .environment(container)
            .preferredColorScheme(dark ? .dark : .light)
    }
}

#Preview("DiaperInputSheet — 라이트") { DiaperInputSheetPreview(dark: false) }
#Preview("DiaperInputSheet — 다크")   { DiaperInputSheetPreview(dark: true) }
