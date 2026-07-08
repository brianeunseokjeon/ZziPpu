// Feature/Feeding/FeedingInputSheet.swift

import SwiftUI

struct FeedingInputSheet: View {
    @Environment(AppContainer.self) private var container
    @State private var vm: FeedingViewModel?
    @Binding var isPresented: Bool

    var body: some View {
        Group {
            if let vm {
                FeedingInputContent(vm: vm, isPresented: $isPresented)
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

    var body: some View {
        NavigationStack {
            Form {
                // 수유 종류 선택
                Section("수유 종류") {
                    feedingTypePicker
                }

                // 종류별 입력 필드
                if vm.selectedType == .formula {
                    Section("분유량 (ml)") {
                        TextField("예: 120", text: $vm.amountMlText)
                            .keyboardType(.numberPad)
                    }
                } else {
                    Section("수유 시간 (분)") {
                        TextField("예: 15", text: $vm.durationText)
                            .keyboardType(.numberPad)
                    }
                }

                // 시작 시각
                Section("시작 시각") {
                    DatePicker("시작", selection: $vm.startedAt, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }

                // 메모
                Section("메모 (선택)") {
                    TextField("메모 입력...", text: $vm.memo, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("수유 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        vm.saveFeeding()
                        isPresented = false
                    }
                    .disabled(!vm.isFormValid)
                    .fontWeight(.semibold)
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
    }

    private var feedingTypePicker: some View {
        Picker("종류", selection: $vm.selectedType) {
            ForEach(FeedingType.allCases, id: \.self) { type in
                Label(type.displayName, systemImage: feedingIcon(type))
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    private func feedingIcon(_ type: FeedingType) -> String {
        switch type {
        case .formula:     return "drop.fill"
        case .breastLeft:  return "arrow.left.circle"
        case .breastRight: return "arrow.right.circle"
        case .breastBoth:  return "arrow.left.arrow.right.circle"
        }
    }
}
