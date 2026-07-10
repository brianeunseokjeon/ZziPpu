// Feature/Home/HomeView.swift
// T2 홈 기록허브:
//   ActiveSessionBanner (진행중 수면 배너)
//   BigActionGrid (4 버튼: 수유/수면/기저귀/놀이 모두 연결)
//   통합 타임라인 (수유+수면+기저귀+놀이 시각 기준 통합 정렬)

import SwiftUI

struct HomeView: View {
    @Environment(AppContainer.self) private var container
    @Environment(ToastCenter.self)  private var toastCenter
    @Environment(\.theme)          private var theme

    @State private var vm: HomeViewModel?
    @State private var showFeedingSheet = false
    @State private var showSleepSheet   = false
    @State private var showDiaperSheet  = false
    @State private var showPlaySheet    = false

    var body: some View {
        NavigationStack {
            if let vm {
                HomeContentView(
                    vm: vm,
                    showFeedingSheet: $showFeedingSheet,
                    showSleepSheet:   $showSleepSheet,
                    showDiaperSheet:  $showDiaperSheet,
                    showPlaySheet:    $showPlaySheet
                )
                // Feeding Sheet
                .dsBottomSheet(
                    isPresented: $showFeedingSheet,
                    options: .init(title: "수유 기록", detents: [.medium, .large])
                ) {
                    FeedingInputSheet(
                        isPresented: $showFeedingSheet,
                        onSaved: { feeding in
                            Task { @MainActor in
                                await vm.saveFeeding(feeding)
                                toastCenter.show(.init(message: "수유 기록 완료!", variant: .success))
                            }
                        }
                    )
                    .environment(container)
                }
                // Sleep Sheet
                .dsBottomSheet(
                    isPresented: $showSleepSheet,
                    options: .init(title: "수면 기록", detents: [.medium])
                ) {
                    SleepInputSheet(
                        isPresented: $showSleepSheet,
                        onSaved: { sleep in
                            Task { @MainActor in
                                await vm.saveSleep(sleep)
                                toastCenter.show(.init(message: "수면 시작!", variant: .success))
                            }
                        }
                    )
                    .environment(container)
                }
                // Diaper Sheet
                .dsBottomSheet(
                    isPresented: $showDiaperSheet,
                    options: .init(title: "기저귀 기록", detents: [.medium, .large])
                ) {
                    DiaperInputSheet(
                        isPresented: $showDiaperSheet,
                        onSaved: { diaper in
                            Task { @MainActor in
                                await vm.saveDiaper(diaper)
                                toastCenter.show(.init(message: "기저귀 기록 완료!", variant: .success))
                            }
                        }
                    )
                    .environment(container)
                }
                // Play Sheet
                .dsBottomSheet(
                    isPresented: $showPlaySheet,
                    options: .init(title: "놀이 기록", detents: [.medium, .large])
                ) {
                    PlayInputSheet(
                        isPresented: $showPlaySheet,
                        onSaved: { play in
                            Task { @MainActor in
                                await vm.savePlay(play)
                                toastCenter.show(.init(message: "놀이 기록 완료!", variant: .success))
                            }
                        }
                    )
                    .environment(container)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.color.background.color)
            }
        }
        .task {
            if vm == nil {
                let newVM = HomeViewModel(
                    feedingRepository: container.feedingRepository,
                    babyRepository:    container.babyRepository,
                    sleepRepository:   container.sleepRepository,
                    diaperRepository:  container.diaperRepository,
                    playRepository:    container.playRepository,
                    babyId:            container.activeBabyId
                )
                vm = newVM
                newVM.loadActiveBaby()
                newVM.loadAll()
            }
        }
    }
}

// MARK: - HomeContentView

private struct HomeContentView: View {
    @Bindable var vm: HomeViewModel
    @Binding var showFeedingSheet: Bool
    @Binding var showSleepSheet:   Bool
    @Binding var showDiaperSheet:  Bool
    @Binding var showPlaySheet:    Bool

    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.theme)         private var theme

    var body: some View {
        VStack(spacing: 0) {
            // AppHeader
            if let baby = vm.activeBaby {
                AppHeader(
                    baby: baby.toHeaderBaby(),
                    selectedDate: $vm.selectedDate,
                    onDateChange: { vm.changeDate($0) }
                )
            } else if vm.isLoadingBaby {
                AppHeaderPlaceholder()
            }

            ScrollView {
                VStack(spacing: 0) {
                    // 진행중 수면 배너
                    if let active = vm.activeSleepSession {
                        ActiveSessionBanner(
                            sleep: active,
                            onEnd: {
                                vm.endActiveSleep()
                                toastCenter.show(.init(message: "수면 종료!", variant: .success))
                            }
                        )
                        .padding(.horizontal, theme.space.screenPaddingX)
                        .padding(.top, theme.space.md)
                    }

                    // BigActionGrid
                    BigActionGrid(
                        showFeedingSheet: $showFeedingSheet,
                        showSleepSheet:   $showSleepSheet,
                        showDiaperSheet:  $showDiaperSheet,
                        showPlaySheet:    $showPlaySheet,
                        hasActiveSleep:   vm.activeSleepSession != nil
                    )
                    .padding(theme.space.md)

                    Divider()
                        .padding(.horizontal, theme.space.screenPaddingX)

                    // 통합 타임라인
                    UnifiedTimeline(
                        items: vm.timelineItems,
                        isLoading: vm.isLoading,
                        onDelete: { item in
                            deleteItem(item)
                        }
                    )
                    .padding(.vertical, theme.space.sm)
                }
            }
        }
        .background(theme.color.background.color)
        .navigationBarHidden(true)
        .alert("오류", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private func deleteItem(_ item: TimelineItem) {
        // domainKind로 어느 도메인 삭제인지 판별
        switch item.domainKind {
        case .feedingFormula, .feedingBreastLeft, .feedingBreastRight,
             .feedingBreastBoth, .feedingSolids:
            if let f = vm.feedings.first(where: { $0.id == item.id }) {
                vm.deleteFeeding(f)
            }
        case .sleep:
            if let s = vm.sleeps.first(where: { $0.id == item.id }) {
                vm.deleteSleep(s)
            }
        case .diaperPee, .diaperPoop, .diaperBoth:
            if let d = vm.diapers.first(where: { $0.id == item.id }) {
                vm.deleteDiaper(d)
            }
        case .play:
            if let p = vm.plays.first(where: { $0.id == item.id }) {
                vm.deletePlay(p)
            }
        }
    }
}

// MARK: - ActiveSessionBanner

private struct ActiveSessionBanner: View {
    let sleep: SleepRecord
    let onEnd: () -> Void

    @State private var elapsed: Int = 0
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.space.sm) {
            Circle()
                .fill(theme.color.domainSleepSolid.color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(theme.color.domainSleepSolid.color.opacity(0.3), lineWidth: 4)
                        .scaleEffect(1.8)
                )

            Text("수면 중 · 경과 \(elapsed)분")
                .font(theme.typography.bodyStrong)
                .foregroundStyle(theme.color.textPrimary.color)

            Spacer()

            DSButton("종료", variant: .secondary, size: .sm) {
                onEnd()
            }
        }
        .padding(.horizontal, theme.space.componentPaddingX)
        .padding(.vertical, theme.space.componentPaddingY)
        .background(theme.color.domainSleepTint.color)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous))
        .onAppear { elapsed = sleep.elapsedMinutes() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            elapsed = sleep.elapsedMinutes()
        }
    }
}

// MARK: - AppHeader Placeholder

private struct AppHeaderPlaceholder: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Circle()
                .fill(theme.color.surfaceSunken.color)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.color.surfaceSunken.color)
                    .frame(width: 64, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.color.surfaceSunken.color)
                    .frame(width: 40, height: 10)
            }
            Spacer()
        }
        .padding(.horizontal, theme.space.screenPaddingX)
        .frame(height: 56)
        .background(theme.color.surface.color)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.color.divider.color)
                .frame(height: 1)
        }
    }
}

// MARK: - BigActionGrid

private struct BigActionGrid: View {
    @Binding var showFeedingSheet: Bool
    @Binding var showSleepSheet:   Bool
    @Binding var showDiaperSheet:  Bool
    @Binding var showPlaySheet:    Bool
    let hasActiveSleep: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: theme.space.md
        ) {
            BigActionButton(
                emoji: "🍼",
                title: "수유",
                color: theme.color.domainFeedingFormulaSolid.color,
                tint:  theme.color.domainFeedingFormulaTint.color
            ) {
                showFeedingSheet = true
            }

            BigActionButton(
                emoji: hasActiveSleep ? "⏹️" : "😴",
                title: hasActiveSleep ? "수면중" : "수면",
                color: theme.color.domainSleepSolid.color,
                tint:  theme.color.domainSleepTint.color,
                isActive: hasActiveSleep
            ) {
                showSleepSheet = true
            }

            BigActionButton(
                emoji: "💧",
                title: "기저귀",
                color: theme.color.domainDiaperPeeSolid.color,
                tint:  theme.color.domainDiaperPeeTint.color
            ) {
                showDiaperSheet = true
            }

            BigActionButton(
                emoji: "🤸",
                title: "놀이",
                color: theme.color.domainPlaySolid.color,
                tint:  theme.color.domainPlayTint.color
            ) {
                showPlaySheet = true
            }
        }
    }
}

// MARK: - BigActionButton

private struct BigActionButton: View {
    let emoji:    String
    let title:    String
    let color:    Color
    let tint:     Color
    var isActive: Bool = false
    let action:   () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.space.sm) {
                Text(emoji)
                    .font(.system(size: 36))
                Text(title)
                    .font(theme.typography.headline)
                    .foregroundStyle(color)
                if isActive {
                    Text("진행중")
                        .font(theme.typography.caption)
                        .foregroundStyle(color.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.space.lg)
        }
        .buttonStyle(.plain)
        .dsCard(style: .interactive)
        .overlay(
            isActive ? RoundedRectangle(cornerRadius: theme.radius.card, style: .continuous)
                .stroke(color, lineWidth: 2) : nil
        )
    }
}

// MARK: - UnifiedTimeline

private struct UnifiedTimeline: View {
    let items: [TimelineItem]
    let isLoading: Bool
    let onDelete: (TimelineItem) -> Void

    @Environment(\.theme) private var theme
    @State private var deleteTarget: TimelineItem? = nil

    var body: some View {
        VStack(spacing: 0) {
            DSSectionHeader(title: "오늘 기록")

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if items.isEmpty {
                DSEmptyState(
                    icon: "list.bullet",
                    message: "이 날의 기록이 없어요"
                )
                .padding(.vertical, theme.space.lg)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        TimelineGroupView(
                            variant: index == 0 ? .highlighted : .normal
                        ) {
                            TimelineItemRow(
                                time:     item.time.timeString,
                                label:    item.label,
                                dotColor: theme.color.solid(for: item.domainKind).color,
                                onEdit:   nil
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteTarget = item
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                        }
                        .padding(.horizontal, theme.space.screenPaddingX)

                        if index < items.count - 1 {
                            Divider()
                                .padding(.horizontal, theme.space.screenPaddingX)
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "기록을 삭제할까요?",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                if let target = deleteTarget {
                    onDelete(target)
                    deleteTarget = nil
                }
            }
            Button("취소", role: .cancel) { deleteTarget = nil }
        }
    }
}

// MARK: - Previews

#Preview("HomeView — 라이트") {
    let container = AppContainer()
    return HomeView()
        .environment(container)
        .environment(\.theme, .zzippu)
        .environment(ToastCenter())
}

#Preview("HomeView — 다크") {
    let container = AppContainer()
    return HomeView()
        .environment(container)
        .environment(\.theme, .zzippu)
        .environment(ToastCenter())
        .preferredColorScheme(.dark)
}
