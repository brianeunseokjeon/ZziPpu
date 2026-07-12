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

    /// 웹정합: 분유 프리셋 6개(웹 ML_PRESETS).
    private let mlPresets = [60, 80, 100, 120, 150, 180]

    /// 프리셋 칩 1개(선택 시 solid 파란 채움/흰 글자, 미선택 흰 배경+회 테두리).
    @ViewBuilder
    private func presetChip(_ ml: Int) -> some View {
        let selected = vm.amountMlInt == ml
        Button { vm.amountMlText = "\(ml)" } label: {
            Text("\(ml)ml")
                .font(theme.typography.body)
                .foregroundStyle(selected ? theme.color.onPrimary.color : theme.color.textSecondary.color)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(selected ? theme.color.statusInfoSolid.color : theme.color.surface.color)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(selected ? .clear : theme.color.borderStrong.color, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        VStack(spacing: theme.space.lg) {
            // 수유 종류 선택 — 분유 / 모유(좌·우·양쪽). 웹은 활동별 분기이나 iOS는 통합 시트.
            VStack(alignment: .leading, spacing: theme.space.xs) {
                Text("수유 종류")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.textSecondary.color)
                HStack(spacing: theme.space.sm) {
                    FeedingTypeButton(type: .formula,     emoji: "🍼",   label: "분유",  tone: .formula, selection: $vm.selectedType)
                    FeedingTypeButton(type: .breastLeft,  emoji: "◀",   label: "왼쪽",  tone: .breast,  selection: $vm.selectedType)
                    FeedingTypeButton(type: .breastRight, emoji: "▶",   label: "오른쪽", tone: .breast,  selection: $vm.selectedType)
                    FeedingTypeButton(type: .breastBoth,  emoji: "◀▶", label: "양쪽",  tone: .breast,  selection: $vm.selectedType)
                }
            }

            if vm.selectedType == .formula {
                // 분유량 — 웹: 큰 파란 숫자(30/bold/blue-600) + 슬라이더 + 6프리셋(solid 선택).
                VStack(spacing: theme.space.md) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(vm.amountMlInt)")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(theme.color.primaryPressed.color)   // blue-600
                        Text("ml")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.color.textSecondary.color)
                    }
                    .frame(maxWidth: .infinity)

                    // 슬라이더 + 원형 −/+ (웹 range + w-10 h-10 원형 버튼).
                    HStack(spacing: theme.space.sm) {
                        RoundStepButton(symbol: "minus") {
                            vm.amountMlText = "\(max(10, vm.amountMlInt - 10))"
                        }
                        Slider(
                            value: Binding(
                                get: { Double(vm.amountMlInt) },
                                set: { vm.amountMlText = "\(Int($0))" }
                            ),
                            in: 10...300, step: 10
                        )
                        .tint(theme.color.statusInfoSolid.color)
                        RoundStepButton(symbol: "plus") {
                            vm.amountMlText = "\(min(300, vm.amountMlInt + 10))"
                        }
                    }

                    // 6 프리셋 (solid 파란 채움 선택). 웹 flex-wrap 대응 → 2행 3열 그리드.
                    Grid(horizontalSpacing: theme.space.sm, verticalSpacing: theme.space.sm) {
                        GridRow {
                            ForEach(mlPresets.prefix(3), id: \.self) { ml in presetChip(ml) }
                        }
                        GridRow {
                            ForEach(mlPresets.suffix(3), id: \.self) { ml in presetChip(ml) }
                        }
                    }
                }
            } else {
                // 모유 — 수유 시간(분).
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
                Text("기록 시간")
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.textSecondary.color)
                DatePicker(
                    "",
                    selection: $vm.startedAt,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }

            // 저장 버튼
            DSButton("저장", variant: .primary, size: .lg) {
                handleSave()
            }
            .disabled(!vm.isFormValid)
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

// MARK: - FeedingTypeButton (분유/모유 좌·우·양쪽 선택)

/// 웹정합: 분유=파란 파스텔, 모유=핑크 파스텔 선택(border-2 이모지 버튼).
private struct FeedingTypeButton: View {
    enum Tone { case formula, breast }
    let type:  FeedingType
    let emoji: String
    let label: String
    let tone:  Tone
    @Binding var selection: FeedingType
    @Environment(\.theme) private var theme

    private var isSelected: Bool { selection == type }

    private var selectedBg: Color {
        tone == .formula ? theme.color.domainFeedingFormulaTint.color
                         : theme.color.domainFeedingBreastLeftTint.color
    }
    private var selectedBorder: Color {
        tone == .formula ? theme.color.statusInfoSolid.color
                         : theme.color.domainFeedingBreastLeftSolid.color
    }

    var body: some View {
        Button { selection = type } label: {
            VStack(spacing: 2) {
                Text(emoji).font(.system(size: 18))
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.color.textPrimary.color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isSelected ? selectedBg : theme.color.surface.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                    .stroke(isSelected ? selectedBorder : theme.color.borderStrong.color,
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - RoundStepButton (웹 원형 −/+ w-10 h-10)

private struct RoundStepButton: View {
    let symbol: String
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(theme.color.textPrimary.color)
                .frame(width: 40, height: 40)
                .background(theme.color.surfaceSunken.color)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FeedingViewModel extension (internal helpers)

extension FeedingViewModel {
    var amountMlInt: Int { Int(amountMlText) ?? 0 }
    var durationInt: Int { Int(durationText) ?? 0 }
}
