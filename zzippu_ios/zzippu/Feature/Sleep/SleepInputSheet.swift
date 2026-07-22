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

    /// 기상 시각(다음날 가능). 기본 .now — 사용자가 조정.
    @State private var endedAt: Date = .now
    /// 아직 자는 중(기상 시각 미정) — 진행중 수면으로 기록.
    @State private var stillSleeping: Bool = false

    private var durationMinutes: Int {
        max(0, Int(endedAt.timeIntervalSince(vm.startedAt) / 60))
    }
    /// 진행중이면 잠든 시각만 있으면 됨. 완료면 기상 > 잠든.
    private var isValid: Bool { stillSleeping || endedAt > vm.startedAt }
    private var durationText: String {
        let h = durationMinutes / 60, m = durationMinutes % 60
        if h > 0 { return "\(h)시간\(m > 0 ? " \(m)분" : "")" }
        return "\(m)분"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: theme.space.md) {
                // 잠든 시각
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text("잠든 시각")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DatePicker(
                        "",
                        selection: $vm.startedAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }

                // 아직 자는 중 토글 — 켜면 기상 시각/잔 시간 숨김(진행중 기록)
                Toggle(isOn: $stillSleeping) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("아직 자는 중이에요")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.color.textPrimary.color)
                        Text("기상 시각은 나중에 기록할 수 있어요")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textTertiary.color)
                    }
                }
                .tint(theme.color.primary.color)

                if !stillSleeping {
                    // 기상 시각 (다음날 가능)
                    VStack(alignment: .leading, spacing: theme.space.xs) {
                        Text("기상 시각")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)
                        DatePicker(
                            "",
                            selection: $endedAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                    }

                    // 잔 시간
                    HStack {
                        Text("잔 시간")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)
                        Spacer()
                        Text(endedAt > vm.startedAt ? durationText : "기상 시각을 잠든 시각 이후로")
                            .font(theme.typography.bodyStrong)
                            .foregroundStyle(endedAt > vm.startedAt ? theme.color.primary.color : theme.color.textTertiary.color)
                    }
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

            DSButton("수면 기록", variant: .primary, size: .lg) {
                handleSave()
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.bottom, theme.space.md)
            .disabled(!isValid)
            .opacity(isValid ? 1 : 0.5)
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
        guard isValid else { return }
        let memo = vm.memo.isEmpty ? nil : vm.memo
        // 자는 중이면 진행중(endedAt nil), 아니면 완료(잠든~기상 + duration).
        let sleep: SleepRecord = stillSleeping
            ? SleepRecord.new(babyId: vm.babyId, startedAt: vm.startedAt, memo: memo)
            : SleepRecord.new(babyId: vm.babyId, startedAt: vm.startedAt,
                              endedAt: endedAt, durationMinutes: durationMinutes, memo: memo)
        vm.resetInputs()
        isPresented = false
        onSaved?(sleep)
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
