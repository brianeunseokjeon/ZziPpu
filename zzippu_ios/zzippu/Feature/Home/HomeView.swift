// Feature/Home/HomeView.swift
// T1 홈 기록허브:
//   AppHeader (activeBaby + 날짜네비)
//   BigActionGrid (4 버튼: 수유만 기능, 나머지 준비중 토스트)
//   오늘 타임라인 (수유 목록, TimelineGroupView/TimelineItemRow)

import SwiftUI

struct HomeView: View {
    @Environment(AppContainer.self) private var container
    @Environment(ToastCenter.self)  private var toastCenter
    @Environment(\.theme)          private var theme

    @State private var vm: HomeViewModel?
    @State private var showFeedingSheet = false

    var body: some View {
        NavigationStack {
            if let vm {
                HomeContentView(
                    vm: vm,
                    showFeedingSheet: $showFeedingSheet
                )
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
                    babyRepository: container.babyRepository,
                    babyId: container.activeBabyId
                )
                vm = newVM
                newVM.loadActiveBaby()
                newVM.loadFeedings()
            }
        }
    }
}

// MARK: - HomeContentView (분리하여 vm 언래핑 이후 사용)

private struct HomeContentView: View {
    @Bindable var vm: HomeViewModel
    @Binding var showFeedingSheet: Bool

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
                    // BigActionGrid
                    BigActionGrid(
                        showFeedingSheet: $showFeedingSheet,
                        onNotReady: {
                            toastCenter.show(.init(message: "준비 중이에요", variant: .info))
                        }
                    )
                    .padding(theme.space.md)

                    Divider()
                        .padding(.horizontal, theme.space.screenPaddingX)

                    // 오늘 타임라인
                    FeedingTimeline(
                        groups: vm.feedingGroups,
                        isLoading: vm.isLoadingFeedings,
                        onDelete: { vm.deleteFeeding($0) }
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
    let onNotReady: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: theme.space.md
        ) {
            BigActionButton(
                emoji:  "🍼",
                title:  "수유",
                color:  theme.color.domainFeedingFormulaSolid.color,
                tint:   theme.color.domainFeedingFormulaTint.color
            ) {
                showFeedingSheet = true
            }

            BigActionButton(
                emoji: "😴",
                title: "수면",
                color: theme.color.domainSleepSolid.color,
                tint:  theme.color.domainSleepTint.color,
                action: onNotReady
            )

            BigActionButton(
                emoji: "💧",
                title: "기저귀",
                color: theme.color.domainDiaperPeeSolid.color,
                tint:  theme.color.domainDiaperPeeTint.color,
                action: onNotReady
            )

            BigActionButton(
                emoji: "🤸",
                title: "놀이",
                color: theme.color.domainPlaySolid.color,
                tint:  theme.color.domainPlayTint.color,
                action: onNotReady
            )
        }
    }
}

// MARK: - BigActionButton

private struct BigActionButton: View {
    let emoji:  String
    let title:  String
    let color:  Color
    let tint:   Color
    let action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.space.sm) {
                Text(emoji)
                    .font(.system(size: 36))
                Text(title)
                    .font(theme.typography.headline)
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.space.lg)
        }
        .buttonStyle(.plain)
        .dsCard(style: .interactive)
    }
}

// MARK: - FeedingTimeline

private struct FeedingTimeline: View {
    let groups:    [FeedingTimelineGroup]
    let isLoading: Bool
    let onDelete:  (Feeding) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            DSSectionHeader(title: "수유 기록")

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if groups.isEmpty {
                DSEmptyState(
                    icon: "drop.slash",
                    message: "이 날의 수유 기록이 없어요"
                )
                .padding(.vertical, theme.space.lg)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(groups) { group in
                        TimelineGroupView(
                            variant: group.isLatest ? .highlighted : .normal
                        ) {
                            ForEach(group.items) { feeding in
                                TimelineItemRow(
                                    time:     feeding.startedAt.timeString,
                                    label:    feeding.timelineLabel,
                                    dotColor: theme.color.solid(for: feeding.domainKind).color,
                                    onEdit:   nil  // 편집 시트는 T2에서 추가
                                )
                            }
                        }
                        .padding(.horizontal, theme.space.screenPaddingX)

                        if group.id != groups.last?.id {
                            Divider()
                                .padding(.horizontal, theme.space.screenPaddingX)
                        }
                    }
                }
            }
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
