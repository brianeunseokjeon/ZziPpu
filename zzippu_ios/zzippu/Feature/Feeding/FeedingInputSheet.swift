// Feature/Feeding/FeedingInputSheet.swift
// 수유 입력 바텀시트.
// onSaved: 저장 직전 Feeding 엔티티를 호출자(HomeView)에게 전달 → HomeViewModel의 낙관적 업데이트에 사용.
// 기존 FeedingViewModel의 입력 상태(selectedType/amountMlText/…)를 그대로 유지.

import SwiftUI

struct FeedingInputSheet: View {
    @Environment(AppContainer.self) private var container
    @State private var vm: FeedingViewModel?
    @Binding var isPresented: Bool
    /// 저장 시 Feeding 엔티티를 호출자에게 전달 (HomeViewModel 낙관적 업데이트용).
    /// nil이면 FeedingViewModel 자체 저장 경로를 사용 (하위호환).
    var onSaved: ((Feeding) -> Void)? = nil

    var body: some View {
        Group {
            if let vm {
                FeedingInputContent(
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
                vm = FeedingViewModel(
                    repository: container.feedingRepository,
                    babyId: container.activeBabyId
                )
            }
        }
    }
}

// MARK: - Content

private struct FeedingInputContent: View {
    @Bindable var vm: FeedingViewModel
    @Binding var isPresented: Bool
    let onSaved: ((Feeding) -> Void)?

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // 수유 종류 칩 토글
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.space.sm) {
                    ForEach(FeedingType.allCases, id: \.self) { type in
                        DSChip(
                            label: type.displayName,
                            isSelected: vm.selectedType == type,
                            variant: .selectable,
                            onTap: { vm.selectedType = type }
                        )
                    }
                }
                .padding(.horizontal, theme.space.screenPaddingX)
            }
            .padding(.vertical, theme.space.md)

            Divider()

            // 입력 필드
            VStack(spacing: theme.space.md) {
                if vm.selectedType == .formula {
                    // 분유량
                    VStack(alignment: .leading, spacing: theme.space.xs) {
                        Text("분유량 (ml)")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)
                        DSNumberStepper(
                            value: Binding(
                                get: { vm.amountMlInt },
                                set: { vm.amountMlText = "\($0)" }
                            ),
                            range: 0...500,
                            step: 10
                        )
                    }
                    // 빠른 선택 칩
                    QuickChipsRow(
                        options: ["100ml", "120ml", "150ml", "180ml"],
                        selection: Binding(
                            get: { vm.amountMlText.isEmpty ? nil : "\(vm.amountMlText)ml" },
                            set: { sel in
                                if let s = sel {
                                    vm.amountMlText = s.replacingOccurrences(of: "ml", with: "")
                                }
                            }
                        )
                    )
                } else {
                    // 수유 시간
                    VStack(alignment: .leading, spacing: theme.space.xs) {
                        Text("수유 시간 (분)")
                            .font(theme.typography.captionStrong)
                            .foregroundStyle(theme.color.textSecondary.color)
                        DSNumberStepper(
                            value: Binding(
                                get: { vm.durationInt },
                                set: { vm.durationText = "\($0)" }
                            ),
                            range: 0...120,
                            step: 1
                        )
                    }
                }

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

            // 저장 버튼
            DSButton("저장", variant: .primary, size: .lg) {
                handleSave()
            }
            .disabled(!vm.isFormValid)
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
        if let onSaved {
            // HomeViewModel 경로: Feeding 엔티티 생성 후 호출자에게 전달
            let amountMl = vm.selectedType == .formula ? Int(vm.amountMlText) : nil
            let duration = vm.selectedType.isBreast ? Int(vm.durationText) : nil
            let feeding = Feeding.new(
                babyId:          vm.babyId,
                type:            vm.selectedType,
                amountMl:        amountMl,
                durationMinutes: duration,
                startedAt:       vm.startedAt,
                memo:            vm.memo.isEmpty ? nil : vm.memo
            )
            vm.resetInputs()
            isPresented = false
            onSaved(feeding)
        } else {
            // 하위호환 경로 (FeedingViewModel 자체 저장)
            vm.saveFeeding()
            isPresented = false
        }
    }
}

// MARK: - FeedingViewModel extension (internal helpers)

extension FeedingViewModel {
    var amountMlInt: Int { Int(amountMlText) ?? 0 }
    var durationInt: Int { Int(durationText) ?? 0 }
}
