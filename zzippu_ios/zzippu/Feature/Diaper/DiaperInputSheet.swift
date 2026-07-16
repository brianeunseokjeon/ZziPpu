// Feature/Diaper/DiaperInputSheet.swift
// 기저귀 입력 바텀시트.

import SwiftUI

struct DiaperInputSheet: View {
    @Environment(AppContainer.self) private var container
    @State private var vm: DiaperViewModel?
    @Binding var isPresented: Bool
    /// 소변/대변은 버튼(진입점)이 결정 — 시트에서 종류 선택 없음. 기본 대변.
    var diaperType: DiaperType = .poo
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
                let model = DiaperViewModel(
                    repository: container.diaperRepository,
                    babyId: container.activeBabyId
                )
                model.prepare(type: diaperType)   // 타입 확정 + 기본값(보통)
                vm = model
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
        // ⚠️ DSBottomSheet가 이미 ScrollView로 감싸므로 여기서 GeometryReader/ScrollView를
        // 또 쓰면 높이 붕괴로 내용이 사라진다. 단순 VStack만 둔다.
        VStack(spacing: 0) {
            VStack(spacing: theme.space.md) {
                // 종류(소변/대변)는 진입 버튼이 결정 → 시트에서 선택 없음.

                // 양 (소변·대변 공통) — 3칩 균등폭
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text("양")
                        .font(theme.typography.captionStrong)
                        .foregroundStyle(theme.color.textSecondary.color)
                    DSSegmentedChips(
                        options:   DiaperAmount.allCases,
                        selection: $vm.selectedAmount,
                        label:     { $0.displayName }
                    )
                }

                // 대변 색 + 질감 (대변/소변+대변 선택 시)
                if vm.selectedType.hasPoo {
                    // 대변 색 — 5칩 compact 균등폭
                    VStack(alignment: .leading, spacing: theme.space.xs) {
                        Text("대변 색")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)
                        DSSegmentedChips(
                            options:   StoolColor.diaperColorCases,
                            selection: $vm.selectedColor,
                            label:     { $0.diaperColorLabel },
                            tint:      { c in theme.color.swatch(for: c.stoolSwatch) },
                            compact:   true
                        )
                    }

                    // 대변 질감 (묽음/보통/찰흙) — 3칩 균등폭
                    VStack(alignment: .leading, spacing: theme.space.xs) {
                        Text("질감")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)
                        DSSegmentedChips(
                            options:   StoolState.diaperTextureCases,
                            selection: $vm.selectedState,
                            label:     { $0.textureShortLabel }
                        )
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

            DSButton("저장", variant: .primary, size: .lg) {
                handleSave()
            }
            .padding(.top, theme.space.md)
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
            amount: vm.selectedAmount,
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
