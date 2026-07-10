// Feature/Development/DevelopmentView.swift
// 발달 탭 — 상단 세그먼트(DSChip)로 [발달 이정표] / [예방접종] 전환.
//   발달: 현재 시기 카드 + 마일스톤 타임라인 (읽기 전용).
//   예방접종: 백신 목록 + 완료 처리 시트.

import SwiftUI

// MARK: - Segment

private enum DevelopmentSegment: String, CaseIterable, Identifiable {
    case development
    case vaccination
    var id: String { rawValue }
    var label: String {
        switch self {
        case .development: return "발달 이정표"
        case .vaccination: return "예방접종"
        }
    }
}

// MARK: - DevelopmentView

struct DevelopmentView: View {

    @Environment(AppContainer.self) private var container
    @Environment(\.theme) private var theme

    @State private var segment: DevelopmentSegment = .development
    @State private var developmentVM: DevelopmentViewModel?
    @State private var vaccinationVM: VaccinationViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                segmentBar

                Group {
                    switch segment {
                    case .development:
                        if let developmentVM {
                            DevelopmentContentView(vm: developmentVM)
                        } else {
                            loading
                        }
                    case .vaccination:
                        if let vaccinationVM {
                            VaccinationContentView(vm: vaccinationVM)
                        } else {
                            loading
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(theme.color.background.color)
            .navigationTitle("발달")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if developmentVM == nil {
                let vm = DevelopmentViewModel(
                    developmentRepository: container.developmentRepository,
                    babyRepository: container.babyRepository,
                    babyId: container.activeBabyId
                )
                developmentVM = vm
                vm.load()
            }
            if vaccinationVM == nil {
                let vm = VaccinationViewModel(
                    repository: container.vaccinationRepository,
                    babyId: container.activeBabyId
                )
                vaccinationVM = vm
                vm.load()
            }
        }
    }

    private var segmentBar: some View {
        HStack(spacing: theme.space.sm) {
            ForEach(DevelopmentSegment.allCases) { seg in
                DSChip(
                    label: seg.label,
                    isSelected: segment == seg,
                    variant: .selectable,
                    onTap: { segment = seg }
                )
            }
            Spacer()
        }
        .padding(.horizontal, theme.space.screenPaddingX)
        .padding(.vertical, theme.space.sm)
    }

    private var loading: some View {
        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("DevelopmentView — 라이트") {
    DevelopmentView()
        .environment(AppContainer.preview)
        .environment(ToastCenter())
        .environment(\.theme, .zzippu)
}

#Preview("DevelopmentView — 다크") {
    DevelopmentView()
        .environment(AppContainer.preview)
        .environment(ToastCenter())
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
