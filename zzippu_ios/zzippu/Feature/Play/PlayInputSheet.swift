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

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: theme.space.md) {
                // 놀이 종류 선택
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text("놀이 종류")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.space.sm) {
                            ForEach(PlayType.allCases, id: \.self) { type in
                                DSChip(
                                    label: type.displayName,
                                    isSelected: vm.selectedType == type,
                                    variant: .selectable,
                                    onTap: { vm.selectedType = type }
                                )
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }

                // 놀이 시간
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text("놀이 시간 (분)")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DSNumberStepper(
                        value: $vm.durationMinutes,
                        range: 1...120,
                        step: 5
                    )
                }

                // 빠른 선택
                QuickChipsRow(
                    options: ["5분", "10분", "15분", "20분", "30분"],
                    selection: Binding(
                        get: {
                            let label = "\(vm.durationMinutes)분"
                            return ["5분", "10분", "15분", "20분", "30분"].contains(label) ? label : nil
                        },
                        set: { sel in
                            if let s = sel, let min = Int(s.replacingOccurrences(of: "분", with: "")) {
                                vm.durationMinutes = min
                            }
                        }
                    )
                )

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
        let endedAt = vm.startedAt.addingTimeInterval(Double(vm.durationMinutes) * 60)
        let play = PlayRecord.new(
            babyId: vm.babyId,
            playType: vm.selectedType,
            startedAt: vm.startedAt,
            endedAt: endedAt,
            durationMinutes: vm.durationMinutes > 0 ? vm.durationMinutes : nil
        )
        vm.resetInputs()
        isPresented = false
        if let onSaved {
            onSaved(play)
        } else {
            vm.savePlay()
        }
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
