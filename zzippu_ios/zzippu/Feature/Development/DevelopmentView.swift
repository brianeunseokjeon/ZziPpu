// Feature/Development/DevelopmentView.swift
// 발달 탭 — 상단 세그먼트(DSChip)로 [발달 이정표] / [예방접종] / [성장] 전환.
//   발달: 현재 시기 카드 + 마일스톤 타임라인 (읽기 전용).
//   예방접종: 백신 목록 + 완료 처리 시트.
//   성장: 키·몸무게 차트·히스토리·추가·수정·삭제 (GrowthDetailView 임베드).

import SwiftUI

// MARK: - Segment

/// 발달 탭 세그먼트. 앱 공용 딥링크(AppNavigationState)에서 참조하므로 internal.
enum DevelopmentSegment: String, CaseIterable, Identifiable {
    case development
    case vaccination
    case growth
    var id: String { rawValue }
    var label: String {
        switch self {
        case .development:  return "발달 이정표"
        case .vaccination:  return "예방접종"
        case .growth:       return "성장"
        }
    }
}

// MARK: - DevelopmentView

struct DevelopmentView: View {

    @Environment(AppContainer.self) private var container
    @Environment(AppNavigationState.self) private var appNav
    @Environment(\.theme) private var theme

    @State private var segment: DevelopmentSegment = .development
    @State private var developmentVM: DevelopmentViewModel?
    @State private var vaccinationVM: VaccinationViewModel?
    @State private var growthVM: GrowthViewModel?

    /// 발달탭 상단 레이아웃 방식(둘 다 구현 — 이 값만 바꾸면 전환).
    /// • true  = 방식 B: 발달 타이틀 + 세그먼트바(이정표·예방접종·성장)를 **상단 고정(스티키)**, 콘텐츠만 스크롤
    /// • false = 방식 A: 타이틀 + 세그먼트바가 콘텐츠와 **함께 스크롤**(당기면 같이 내려감)
    private let stickyHeader = true

    /// 방식 A에서 각 콘텐츠 스크롤 최상단에 얹을 헤더(방식 B면 nil → 고정 헤더가 대신 렌더).
    private var scrollingHeader: AnyView? {
        stickyHeader ? nil : AnyView(headerView)
    }

    /// 발달 타이틀 + 세그먼트바 묶음.
    private var headerView: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("발달")
                .font(.largeTitle.bold())
                .foregroundStyle(theme.color.textPrimary.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.space.screenPaddingX)
                .padding(.top, theme.space.sm)
            segmentBar
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 방식 B(stickyHeader=true): 타이틀+세그먼트바를 상단 고정.
                if stickyHeader {
                    headerView
                }

                Group {
                    switch segment {
                    case .development:
                        if let developmentVM {
                            DevelopmentContentView(vm: developmentVM, header: scrollingHeader)
                        } else {
                            loading
                        }
                    case .vaccination:
                        if let vaccinationVM {
                            VaccinationContentView(vm: vaccinationVM, header: scrollingHeader)
                        } else {
                            loading
                        }
                    case .growth:
                        if let growthVM {
                            // 발달 탭이 이미 NavigationStack → GrowthDetailView는 콘텐츠로 임베드.
                            GrowthDetailView(vm: growthVM, header: scrollingHeader)
                        } else {
                            loading
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(theme.color.background.color)
            .navigationBarHidden(true)   // 시스템 타이틀 대신 커스텀 헤더(headerView) 사용
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
            if growthVM == nil {
                growthVM = GrowthViewModel(
                    growthRepository: container.growthRepository,
                    babyId: container.activeBabyId,
                    babyRepository: container.babyRepository,
                    guidelineRepository: container.guidelineRepository
                )
            }
            consumePendingSegment()
        }
        .onChange(of: appNav.developmentSegment) { _, _ in
            consumePendingSegment()
        }
    }

    /// 딥링크로 지정된 세그먼트가 있으면 전환 후 소비(nil로 클리어).
    private func consumePendingSegment() {
        if let pending = appNav.developmentSegment {
            segment = pending
            appNav.developmentSegment = nil
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
        .environment(AppNavigationState())
        .environment(ToastCenter())
        .environment(\.theme, .zzippu)
}

#Preview("DevelopmentView — 다크") {
    DevelopmentView()
        .environment(AppContainer.preview)
        .environment(AppNavigationState())
        .environment(ToastCenter())
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
