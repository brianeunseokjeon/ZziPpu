// Feature/Home/HomeView.swift
// 홈 — 웹(page.tsx / BigActionGrid / TimelineScrollView / DayTimeline) 재현.
//   • 상단 고정: 6버튼 퀵기록(분유·모유·소변·대변·수면시작·터미타임시작)
//   • 하단: 여러 날 스크롤 피드(날짜 섹션: 오늘/어제/그제/"N월 N일 (요일)"), 아래로 과거 로드(최대 60일)
//   • 과거 날짜 선택 시 단일 일자 포커스 뷰
//   • 활성 세션(수면/터미타임)은 버튼이 "종료"로 전환.
// DS 컴포넌트(AppHeader/TimelineGroupView/TimelineItemRow/DSCard/DSBottomSheet/DSEmptyState) + theme 토큰만 사용.

import SwiftUI

struct HomeView: View {
    @Environment(AppContainer.self) private var container
    @Environment(ToastCenter.self)  private var toastCenter
    @Environment(\.theme)           private var theme

    @State private var vm: HomeViewModel?

    // 상세 입력 시트 (모유 / 대변 / 과거 날짜 입력)
    @State private var feedingSheetType: FeedingType? = nil   // 모유 상세
    @State private var showBreastSheet  = false
    @State private var showDiaperSheet  = false               // 대변 상세
    @State private var showFeedingSheet = false               // 과거 분유
    @State private var showSleepSheet   = false               // 과거 수면
    @State private var showPlaySheet    = false               // 과거 터미타임

    var body: some View {
        NavigationStack {
            if let vm {
                HomeContentView(
                    vm: vm,
                    onAction: { handleAction($0, vm: vm) }
                )
                .dsBottomSheet(
                    isPresented: $showBreastSheet,
                    options: .init(title: "모유 기록", detents: [.medium, .large])
                ) {
                    FeedingInputSheet(
                        isPresented: $showBreastSheet,
                        onSaved: { feeding in
                            Task { @MainActor in
                                await vm.saveFeeding(feeding)
                                toastCenter.show(.init(message: "모유 기록 완료!", variant: .success))
                            }
                        }
                    )
                    .environment(container)
                }
                .dsBottomSheet(
                    isPresented: $showDiaperSheet,
                    options: .init(title: "대변 기록", detents: [.medium, .large])
                ) {
                    DiaperInputSheet(
                        isPresented: $showDiaperSheet,
                        onSaved: { diaper in
                            Task { @MainActor in
                                await vm.saveDiaper(diaper)
                                toastCenter.show(.init(message: "대변 기록 완료!", variant: .success))
                            }
                        }
                    )
                    .environment(container)
                }
                .dsBottomSheet(
                    isPresented: $showFeedingSheet,
                    options: .init(title: "분유 기록", detents: [.medium, .large])
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
                .dsBottomSheet(
                    isPresented: $showSleepSheet,
                    options: .init(title: "수면 기록", detents: [.medium])
                ) {
                    SleepInputSheet(
                        isPresented: $showSleepSheet,
                        onSaved: { sleep in
                            Task { @MainActor in
                                await vm.saveSleep(sleep)
                                toastCenter.show(.init(message: "수면 기록 완료!", variant: .success))
                            }
                        }
                    )
                    .environment(container)
                }
                .dsBottomSheet(
                    isPresented: $showPlaySheet,
                    options: .init(title: "터미타임 기록", detents: [.medium, .large])
                ) {
                    PlayInputSheet(
                        isPresented: $showPlaySheet,
                        onSaved: { play in
                            Task { @MainActor in
                                await vm.savePlay(play)
                                toastCenter.show(.init(message: "터미타임 기록 완료!", variant: .success))
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
                newVM.loadInitial()
            }
        }
    }

    // MARK: - 버튼 액션 라우팅

    private func handleAction(_ action: HomeAction, vm: HomeViewModel) {
        // 과거 날짜 포커스 모드: 모든 버튼이 시각 입력 시트를 연다 (웹 동작).
        if vm.isFocusingPast {
            switch action {
            case .formula:                 showFeedingSheet = true
            case .breast:                  showBreastSheet  = true
            case .pee, .poo:               showDiaperSheet  = true
            case .sleep:                   showSleepSheet   = true
            case .play:                    showPlaySheet    = true
            }
            return
        }

        switch action {
        case .formula:
            Task { @MainActor in
                let msg = await vm.quickSaveFormula()
                toastCenter.show(.init(message: msg, variant: .success))
            }
        case .breast:
            showBreastSheet = true
        case .pee:
            Task { @MainActor in
                let msg = await vm.quickSavePee()
                toastCenter.show(.init(message: msg, variant: .success))
            }
        case .poo:
            showDiaperSheet = true
        case .sleep:
            Task { @MainActor in
                let msg = await vm.toggleSleep()
                toastCenter.show(.init(message: msg, variant: .success))
            }
        case .play:
            Task { @MainActor in
                let msg = await vm.togglePlay()
                toastCenter.show(.init(message: msg, variant: .success))
            }
        }
    }
}

// MARK: - HomeAction

enum HomeAction { case formula, breast, pee, poo, sleep, play }

// MARK: - HomeContentView

private struct HomeContentView: View {
    @Bindable var vm: HomeViewModel
    let onAction: (HomeAction) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            if let baby = vm.activeBaby {
                AppHeader(
                    baby: baby.toHeaderBaby(),
                    selectedDate: $vm.selectedDate,
                    onDateChange: { vm.changeDate($0) }
                )
            } else if vm.isLoadingBaby {
                AppHeaderPlaceholder()
            }

            if vm.isFocusingPast {
                PastFocusView(vm: vm, onAction: onAction)
            } else {
                TodayView(vm: vm, onAction: onAction)
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

// MARK: - TodayView (고정 상단 그리드 + 여러 날 스크롤 피드)

private struct TodayView: View {
    @Bindable var vm: HomeViewModel
    let onAction: (HomeAction) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // ── 고정 상단: 6버튼 ──
            BigActionGrid(
                hasActiveSleep: vm.activeSleepSession != nil,
                hasActivePlay:  vm.activePlaySession != nil,
                onAction: onAction
            )
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.top, theme.space.sm)
            .padding(.bottom, theme.space.sm)
            .background(theme.color.surface.color)
            .overlay(alignment: .bottom) {
                Rectangle().fill(theme.color.divider.color).frame(height: 1)
            }

            // ── 여러 날 스크롤 피드 ──
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(vm.loadedDays, id: \.self) { day in
                        Section {
                            DayTimelineSection(vm: vm, day: day)
                        } header: {
                            DateSectionHeader(day: day)
                        }
                    }

                    if vm.reachedMaxDays {
                        Text("최대 \(HomeViewModel.maxDays)일 전까지 표시됩니다")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textTertiary.color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.space.md)
                    } else {
                        // 하단 sentinel — 나타나면 과거 하루 append
                        Color.clear
                            .frame(height: 1)
                            .onAppear { vm.loadOlderDay() }
                    }
                }
                .padding(.bottom, theme.space.lg)
            }
            .background(theme.color.background.color)
        }
    }
}

// MARK: - PastFocusView (과거 날짜 단일 일자)

private struct PastFocusView: View {
    @Bindable var vm: HomeViewModel
    let onAction: (HomeAction) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: theme.space.sm) {
                // 과거 기록 안내 배너
                HStack(spacing: theme.space.xs) {
                    Text("📅")
                    Text("\(vm.selectedDate.relativeLabel)에 기록 중 · 버튼을 누르면 시각을 입력해요")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.statusWarningFg.color)
                    Spacer()
                    Button {
                        vm.changeDate(Date())
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.left").font(.system(size: 11, weight: .semibold))
                            Text("오늘로").font(theme.typography.captionStrong)
                        }
                        .foregroundStyle(theme.color.primary.color)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, theme.space.componentPaddingX)
                .padding(.vertical, theme.space.sm)
                .background(theme.color.statusWarningBg.color)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous))

                BigActionGrid(
                    hasActiveSleep: false,
                    hasActivePlay:  false,
                    onAction: onAction
                )
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.vertical, theme.space.sm)
            .background(theme.color.surface.color)
            .overlay(alignment: .bottom) {
                Rectangle().fill(theme.color.divider.color).frame(height: 1)
            }

            ScrollView {
                DayTimelineSection(vm: vm, day: Calendar.current.startOfDay(for: vm.selectedDate))
                    .padding(.bottom, theme.space.lg)
            }
            .background(theme.color.background.color)
        }
    }
}

// MARK: - DateSectionHeader (오늘/어제/그제/"N월 N일 (요일)")

private struct DateSectionHeader: View {
    let day: Date
    @Environment(\.theme) private var theme

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    private var label: String {
        let cal = Calendar.current
        if cal.isDateInToday(day)     { return "오늘" }
        if cal.isDateInYesterday(day) { return "어제" }
        if let two = cal.date(byAdding: .day, value: -2, to: cal.startOfDay(for: Date())),
           cal.isDate(day, inSameDayAs: two) { return "그제" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일 (E)"
        return fmt.string(from: day)
    }

    var body: some View {
        HStack(spacing: theme.space.xs) {
            Text(label)
                .font(theme.typography.captionStrong)
                .foregroundStyle(isToday ? theme.color.primary.color : theme.color.textSecondary.color)
            Spacer()
        }
        .padding(.horizontal, theme.space.screenPaddingX)
        .padding(.vertical, theme.space.sm)
        .frame(maxWidth: .infinity)
        .background(theme.color.surface.color.opacity(0.97))
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.color.divider.color).frame(height: 1)
        }
    }
}

// MARK: - DayTimelineSection (단일 일자 타임라인)

private struct DayTimelineSection: View {
    @Bindable var vm: HomeViewModel
    let day: Date

    @Environment(\.theme) private var theme
    @Environment(ToastCenter.self) private var toastCenter
    @State private var deleteTarget: TimelineItem? = nil
    @State private var editRecord: EditableRecord? = nil

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        let items = vm.timelineItems(for: day)

        Group {
            if vm.isLoading(for: day) && items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if items.isEmpty {
                DSEmptyState(icon: "list.bullet", message: "이 날의 기록이 없어요")
                    .padding(.vertical, theme.space.md)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    TimelineGroupView(
                        variant: (isToday && index == 0) ? .highlighted : .normal
                    ) {
                        TimelineItemRow(
                            time:     item.time.timeString,
                            label:    item.label,
                            dotColor: theme.color.solid(for: item.domainKind).color,
                            onEdit:   { editRecord = vm.editableRecord(for: item, on: day) }
                        )
                        // LazyVStack 에서는 swipeActions 가 동작하지 않으므로
                        // 길게 눌러 편집/삭제하는 컨텍스트 메뉴로 제공.
                        .contextMenu {
                            Button {
                                editRecord = vm.editableRecord(for: item, on: day)
                            } label: {
                                Label("편집", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                deleteTarget = item
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                    .padding(.horizontal, theme.space.screenPaddingX)

                    if index < items.count - 1 {
                        Divider().padding(.horizontal, theme.space.screenPaddingX)
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
                if let t = deleteTarget { vm.delete(t, on: day); deleteTarget = nil }
            }
            Button("취소", role: .cancel) { deleteTarget = nil }
        }
        .dsBottomSheet(
            isPresented: Binding(
                get: { editRecord != nil },
                set: { if !$0 { editRecord = nil } }
            ),
            options: .init(title: editSheetTitle, detents: [.medium, .large])
        ) {
            if let record = editRecord {
                RecordEditSheet(
                    record: record,
                    vm: vm,
                    onClose: { editRecord = nil },
                    onToast: { msg in toastCenter.show(.init(message: msg, variant: .success)) }
                )
            }
        }
    }

    /// 편집 시트 타이틀 (웹 titleMap 재현).
    private var editSheetTitle: String {
        switch editRecord {
        case .feeding(let f):
            return f.type == .formula ? "🍼 분유 수정" : "🤱 모유 수정"
        case .diaper(let d):
            switch d.diaperType {
            case .pee:  return "💧 소변 수정"
            case .poo:  return "💩 대변 수정"
            case .both: return "💧💩 배변 수정"
            }
        case .sleep: return "😴 수면 수정"
        case .play:  return "🎈 놀이 수정"
        case .none:  return "수정"
        }
    }
}

// MARK: - BigActionGrid (6버튼 3열 x 2행)

private struct BigActionGrid: View {
    let hasActiveSleep: Bool
    let hasActivePlay:  Bool
    let onAction: (HomeAction) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: theme.space.sm), count: 3),
            spacing: theme.space.sm
        ) {
            BigActionButton(emoji: "🍼", label: "분유", kind: .feedingFormula) { onAction(.formula) }
            BigActionButton(emoji: "🤱", label: "모유", kind: .feedingBreastBoth) { onAction(.breast) }
            BigActionButton(emoji: "💧", label: "소변", kind: .diaperPee) { onAction(.pee) }
            BigActionButton(emoji: "💩", label: "대변", kind: .diaperPoop) { onAction(.poo) }
            BigActionButton(
                emoji: "😴",
                label: hasActiveSleep ? "수면 종료" : "수면 시작",
                kind: .sleep, isActive: hasActiveSleep
            ) { onAction(.sleep) }
            BigActionButton(
                emoji: "🎈",
                label: hasActivePlay ? "터미타임 종료" : "터미타임 시작",
                kind: .play, isActive: hasActivePlay
            ) { onAction(.play) }
        }
    }
}

// MARK: - BigActionButton

private struct BigActionButton: View {
    let emoji: String
    let label: String
    let kind:  DomainKind
    var isActive: Bool = false
    let action: () -> Void

    @Environment(\.theme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.space.xs) {
                Text(emoji).font(.system(size: 22))
                Text(label)
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.color.solid(for: kind).color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.space.md)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.controlLg, style: .continuous)
                    .fill(theme.color.tint(for: kind).color)
                    // press 시 도메인 색 tint를 살짝 진하게(피드백).
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.controlLg, style: .continuous)
                            .fill(theme.color.solid(for: kind).color.opacity(isPressed ? 0.12 : 0))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.controlLg, style: .continuous)
                    .stroke(theme.color.solid(for: kind).color,
                            lineWidth: isActive ? 2 : 0)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - AppHeader Placeholder

private struct AppHeaderPlaceholder: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Circle().fill(theme.color.surfaceSunken.color).frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                RoundedRectangle(cornerRadius: 4).fill(theme.color.surfaceSunken.color).frame(width: 64, height: 14)
                RoundedRectangle(cornerRadius: 4).fill(theme.color.surfaceSunken.color).frame(width: 40, height: 10)
            }
            Spacer()
        }
        .padding(.horizontal, theme.space.screenPaddingX)
        .frame(height: 56)
        .background(theme.color.surface.color)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.color.divider.color).frame(height: 1)
        }
    }
}

// MARK: - Previews

#Preview("HomeView — 라이트") {
    HomeView()
        .environment(AppContainer())
        .environment(\.theme, .zzippu)
        .environment(ToastCenter())
}

#Preview("HomeView — 다크") {
    HomeView()
        .environment(AppContainer())
        .environment(\.theme, .zzippu)
        .environment(ToastCenter())
        .preferredColorScheme(.dark)
}
