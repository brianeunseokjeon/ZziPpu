// Feature/Sleep/SleepInputSheet.swift
// 수면 입력 바텀시트.

import SwiftUI

struct SleepInputSheet: View {
    @Environment(AppContainer.self) private var container
    @State private var vm: SleepViewModel?
    @Binding var isPresented: Bool
    var onSaved: ((SleepRecord) -> Void)? = nil

    var body: some View {
        Group {
            if let vm {
                SleepInputContent(
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
                vm = SleepViewModel(
                    repository: container.sleepRepository,
                    babyId: container.activeBabyId
                )
            }
        }
    }
}

// MARK: - Content

private struct SleepInputContent: View {
    @Bindable var vm: SleepViewModel
    @Binding var isPresented: Bool
    let onSaved: ((SleepRecord) -> Void)?

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: theme.space.md) {
                // 시작 시각
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text("시작 시각")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DatePicker(
                        "",
                        selection: $vm.startedAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }

                // 메모 (optional)
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text("메모 (선택)")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DSTextField(placeholder: "메모를 입력하세요", text: $vm.memo)
                }
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.vertical, theme.space.md)

            Spacer()

            DSButton("수면 시작", variant: .primary, size: .lg) {
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
        let sleep = SleepRecord.new(
            babyId: vm.babyId,
            startedAt: vm.startedAt,
            memo: vm.memo.isEmpty ? nil : vm.memo
        )
        vm.resetInputs()
        isPresented = false
        if let onSaved {
            onSaved(sleep)
        } else {
            vm.startSleep()
        }
    }
}

// MARK: - Preview

private struct SleepInputSheetPreview: View {
    @State private var show = true
    let container = AppContainer()
    let dark: Bool
    var body: some View {
        Color.clear
            .dsBottomSheet(isPresented: $show, options: .init(title: "수면 기록", detents: [.medium])) {
                SleepInputSheet(isPresented: $show).environment(container)
            }
            .environment(\.theme, .zzippu)
            .environment(container)
            .preferredColorScheme(dark ? .dark : .light)
    }
}

#Preview("SleepInputSheet — 라이트") { SleepInputSheetPreview(dark: false) }
#Preview("SleepInputSheet — 다크")   { SleepInputSheetPreview(dark: true) }
