// Feature/Play/PlayInputSheet.swift
// 놀이 입력 바텀시트.

import SwiftUI

struct PlayInputSheet: View {
    @Environment(AppContainer.self) private var container
    @State private var vm: PlayViewModel?
    @Binding var isPresented: Bool
    var onSaved: ((PlayRecord) -> Void)? = nil

    var body: some View {
        Group {
            if let vm {
                PlayInputContent(
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
                vm = PlayViewModel(
                    repository: container.playRepository,
                    babyId: container.activeBabyId
                )
            }
        }
    }
}

// MARK: - Content

private struct PlayInputContent: View {
    @Bindable var vm: PlayViewModel
    @Binding var isPresented: Bool
    let onSaved: ((PlayRecord) -> Void)?

    @Environment(\.theme) private var theme

    /// 지속시간 프리셋(분). nil 선택 = "시작만 기록".
    @State private var durationChoice: Int? = nil
    @State private var customMode: Bool = false
    @State private var customText: String = ""

    private static let presets = [1, 2, 3, 5, 7, 10]

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

                // 지속시간 — 시작만 기록 / 프리셋 / 직접입력 (공용 DSSelectChip·FlowLayout)
                VStack(alignment: .leading, spacing: theme.space.sm) {
                    Text("지속시간")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    FlowLayout(spacing: theme.space.sm) {
                        DSSelectChip(label: "시작만", isSelected: durationChoice == nil && !customMode) {
                            durationChoice = nil; customMode = false
                        }
                        ForEach(Self.presets, id: \.self) { m in
                            DSSelectChip(label: "\(m)분", isSelected: !customMode && durationChoice == m) {
                                durationChoice = m; customMode = false
                            }
                        }
                        DSSelectChip(label: "직접입력", isSelected: customMode) {
                            customMode = true; durationChoice = nil
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if customMode {
                        HStack(spacing: theme.space.sm) {
                            DSTextField(placeholder: "분", text: $customText, keyboardType: .numberPad)
                            Text("분").font(theme.typography.body)
                                .foregroundStyle(theme.color.textSecondary.color)
                        }
                    }
                }
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.vertical, theme.space.md)

            Spacer()

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
        // 지속시간: 직접입력이면 입력값, 아니면 프리셋. "시작만"이면 nil(시점만 기록).
        let minutes: Int? = customMode ? Int(customText).flatMap { $0 > 0 ? $0 : nil } : durationChoice
        let play: PlayRecord
        if let m = minutes {
            play = PlayRecord.new(
                babyId: vm.babyId,
                playType: .tummyTime,
                startedAt: vm.startedAt,
                endedAt: vm.startedAt.addingTimeInterval(Double(m) * 60),
                durationMinutes: m
            )
        } else {
            // 시작만 기록(시점만).
            play = PlayRecord.new(babyId: vm.babyId, playType: .tummyTime, startedAt: vm.startedAt)
        }
        vm.resetInputs()
        isPresented = false
        onSaved?(play)
    }
}

// MARK: - Preview

private struct PlayInputSheetPreview: View {
    @State private var show = true
    let container = AppContainer()
    let dark: Bool
    var body: some View {
        Color.clear
            .dsBottomSheet(isPresented: $show, options: .init(title: "놀이 기록", detents: [.medium, .large])) {
                PlayInputSheet(isPresented: $show).environment(container)
            }
            .environment(\.theme, .zzippu)
            .environment(container)
            .preferredColorScheme(dark ? .dark : .light)
    }
}

#Preview("PlayInputSheet — 라이트") { PlayInputSheetPreview(dark: false) }
#Preview("PlayInputSheet — 다크")   { PlayInputSheetPreview(dark: true) }
