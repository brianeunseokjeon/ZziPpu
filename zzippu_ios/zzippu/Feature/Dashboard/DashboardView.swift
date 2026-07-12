// Feature/Dashboard/DashboardView.swift
// T3 대시보드 탭 — 건강앱 스타일 메트릭 카드 요약 화면.
// 카드 탭 → 상세 차트 push (NavigationStack).

import SwiftUI

// MARK: - DashboardDestination

enum DashboardDestination: Hashable {
    case feedingDetail
    case sleepDetail
    case diaperDetail
    case playDetail
    case growthDetail
}

// MARK: - DashboardView

struct DashboardView: View {

    @Environment(AppContainer.self) private var container
    @Environment(\.theme) private var theme

    @State private var vm: DashboardViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    DashboardContentView(vm: vm)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationDestination(for: DashboardDestination.self) { dest in
                destinationView(for: dest)
            }
        }
        .onAppear {
            if vm == nil {
                vm = DashboardViewModel(
                    dashboardRepository: container.dashboardRepository,
                    feedingRepository:   container.feedingRepository,
                    sleepRepository:     container.sleepRepository,
                    diaperRepository:    container.diaperRepository,
                    playRepository:      container.playRepository,
                    growthRepository:    container.growthRepository,
                    babyRepository:      container.babyRepository,
                    guidelineRepository: container.guidelineRepository,
                    babyId:              container.activeBabyId
                )
                vm?.loadAll()
            }
        }
    }

    @ViewBuilder
    private func destinationView(for dest: DashboardDestination) -> some View {
        switch dest {
        case .feedingDetail:
            if let vm {
                FeedingDetailView(dashboardVM: vm)
            }
        case .sleepDetail:
            if let vm {
                SleepDetailView(dashboardVM: vm)
            }
        case .diaperDetail:
            if let vm {
                DiaperDetailView(dashboardVM: vm)
            }
        case .playDetail:
            if let vm {
                PlayDetailView(dashboardVM: vm)
            }
        case .growthDetail:
            GrowthDetailView(
                vm: GrowthViewModel(
                    growthRepository: container.growthRepository,
                    babyId: container.activeBabyId,
                    babyRepository: container.babyRepository,
                    guidelineRepository: container.guidelineRepository
                )
            )
        }
    }
}

// MARK: - DashboardContentView

struct DashboardContentView: View {

    @Bindable var vm: DashboardViewModel
    @Environment(\.theme) private var theme

    // 도메인 값(VM 튜플) → DS 세그먼트(theme 색 주입). DS는 Domain 비의존.
    private var feedingDonutSegments: [DSDonutSegment] {
        vm.feedingDonutSegments.map { seg in
            DSDonutSegment(
                value: seg.value,
                color: seg.isFormula
                    ? theme.color.domainFeedingFormulaSolid.color
                    : theme.color.domainFeedingBreastBothSolid.color,
                label: seg.label
            )
        }
    }

    private var diaperDonutSegments: [DSDonutSegment] {
        vm.diaperDonutSegments.map { seg in
            DSDonutSegment(
                value: seg.value,
                color: seg.isPee
                    ? theme.color.domainDiaperPeeSolid.color
                    : theme.color.domainDiaperPoopSolid.color,
                label: seg.label
            )
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: theme.space.sectionGap) {
                // ① 오늘의 분석 — 가이드 비교 인사이트(최상단 롤업)
                TodayInsightsSection(insights: vm.insights, headline: vm.insightsHeadline)
                    .padding(.horizontal, theme.space.screenPaddingX)

                // ② 오늘 수유량 대표 지표(화면 유일 display36 · 링 게이지)
                FeedingAdequacyCard(
                    totalMl: vm.dailySummary.totalFeedingMl,
                    recommendedRange: vm.feedingRecommendedRange
                )
                .padding(.horizontal, theme.space.screenPaddingX)

                // ②-b 수유량 추세(7/14일 막대 차트) — 웹 정합
                FeedingTrendCard(
                    days: vm.feedingTrendDays,
                    dayCount: vm.trendDayCount,
                    guideline: vm.feedingTrendGuideline,
                    onSelectDayCount: { vm.trendDayCount = $0 }
                )
                .padding(.horizontal, theme.space.screenPaddingX)

                // ③ 2열 지표 카드 그리드 (수유·수면·기저귀·놀이)
                DSSectionHeader(title: "오늘 요약")

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    NavigationLink(value: DashboardDestination.feedingDetail) {
                        MetricCard(
                            title:     "수유",
                            value:     vm.feedingSummaryText,
                            subValue:  vm.feedingSubText,
                            symbol:    "drop.fill",
                            color:     theme.color.domainFeedingFormulaSolid.color,
                            points:    vm.feedingSparkPoints,
                            sparkKind: .bar,
                            donutSegments: feedingDonutSegments,
                            donutCenter:   vm.feedingDonutCenter,
                            onTap:     {}
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: DashboardDestination.sleepDetail) {
                        MetricCard(
                            title:     "수면",
                            value:     vm.sleepSummaryText,
                            subValue:  "\(vm.dailySummary.sleepCount)회",
                            symbol:    "moon.fill",
                            color:     theme.color.domainSleepSolid.color,
                            points:    vm.sleepSparkPoints,
                            sparkKind: .line,
                            onTap:     {}
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: DashboardDestination.diaperDetail) {
                        MetricCard(
                            title:     "기저귀",
                            value:     vm.diaperSummaryText,
                            subValue:  vm.diaperSubText,
                            symbol:    "heart.fill",
                            color:     theme.color.domainDiaperPeeSolid.color,
                            points:    vm.diaperSparkPoints,
                            sparkKind: .bar,
                            donutSegments: diaperDonutSegments,
                            donutCenter:   vm.diaperDonutCenter,
                            onTap:     {}
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: DashboardDestination.playDetail) {
                        MetricCard(
                            title:     "놀이",
                            value:     vm.playSummaryText,
                            subValue:  vm.playSubText,
                            symbol:    "figure.play",
                            color:     theme.color.domainPlaySolid.color,
                            points:    vm.playSparkPoints,
                            sparkKind: .bar,
                            onTap:     {}
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, theme.space.screenPaddingX)

                // ④ 다음 수유/수면 예측 (적정 크기)
                NextFeedingCard(prediction: vm.prediction)
                    .padding(.horizontal, theme.space.screenPaddingX)

                // ⑤ 성장 요약 (전폭 카드)
                NavigationLink(value: DashboardDestination.growthDetail) {
                    GrowthMetricCard(
                        weight: vm.latestWeightText,
                        height: vm.latestHeightText,
                        onTap:  {}
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, theme.space.screenPaddingX)
            }
            .padding(.vertical, theme.space.screenPaddingY)
        }
        .navigationTitle("대시보드")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            vm.loadAll()
        }
        .overlay {
            if vm.isLoading && vm.dailySummary == .empty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Preview

#Preview("DashboardView — light") {
    DashboardView()
        .environment(AppContainer.preview)
        .environment(ToastCenter())
        .environment(\.theme, .zzippu)
}

#Preview("DashboardView — dark") {
    DashboardView()
        .environment(AppContainer.preview)
        .environment(ToastCenter())
        .environment(\.theme, .zzippu)
        .preferredColorScheme(.dark)
}
