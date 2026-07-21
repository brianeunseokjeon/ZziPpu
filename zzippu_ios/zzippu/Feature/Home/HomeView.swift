// Feature/Home/HomeView.swift
// 홈 — 웹(page.tsx / BigActionGrid / TimelineScrollView / DayTimeline) 재현.
//   • 상단 고정: 6버튼 퀵기록(분유·모유·소변·대변·수면시작·터미타임시작)
//   • 하단: 여러 날 스크롤 피드(날짜 섹션: 오늘/어제/그제/"N월 N일 (요일)"), 아래로 과거 로드(최대 60일)
//   • 과거 날짜 선택 시 단일 일자 포커스 뷰
//   • 활성 세션(수면)은 버튼이 "종료"로 전환. 터미타임은 즉시 기록(분유처럼 시점만).
// DS 컴포넌트(AppHeader/TimelineGroupView/TimelineItemRow/DSCard/DSBottomSheet/DSEmptyState) + theme 토큰만 사용.

import SwiftUI

struct HomeView: View {
    @Environment(AppContainer.self) private var container
    @Environment(ToastCenter.self)  private var toastCenter
    @Environment(\.theme)           private var theme

    @State private var vm: HomeViewModel?
    @State private var quickBarStore = QuickBarStore()

    // 상세 입력 시트 (모유 / 대변 / 과거 날짜 입력)
    @State private var feedingSheetType: FeedingType? = nil   // 모유 상세
    @State private var showBreastSheet  = false
    @State private var showDiaperSheet  = false               // 기저귀 상세(과거 소변/대변)
    @State private var pendingDiaperType: DiaperType = .poo   // 시트에 넘길 종류(버튼이 결정)
    @State private var showFeedingSheet = false               // 과거 분유
    @State private var showSleepSheet   = false               // 과거 수면
    @State private var showPlaySheet    = false               // 과거 터미타임
    @State private var showQuickBarEdit = false               // 빠른기록 편집 시트
    @State private var careCreateCategory: CareCategory? = nil // 영양제·약·목욕(과거) 생성 시트

    var body: some View {
        NavigationStack {
            if let vm {
                HomeContentView(
                    vm: vm,
                    quickBarStore: quickBarStore,
                    onAction: { handleAction($0, vm: vm) },
                    onEditQuickBar: { showQuickBarEdit = true }
                )
                // 서버→로컬 동기화(pull) 완료 시 보이는 날짜 재로드 →
                // 웹/다른 기기에서 만든 기록이 앱에 즉시 반영된다(재시작 불필요).
                .onChange(of: container.syncCoordinator?.lastSyncedAt) { _, _ in
                    vm.reloadVisibleDays()
                }
                .dsBottomSheet(
                    isPresented: $showBreastSheet,
                    options: .init(title: "🤱 모유 기록", detents: [.medium, .large])
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
                    options: .init(
                        title: pendingDiaperType == .pee ? "💧 소변 기록" : "💩 대변 기록",
                        detents: [.fraction(0.62), .large]
                    )
                ) {
                    DiaperInputSheet(
                        isPresented: $showDiaperSheet,
                        diaperType: pendingDiaperType,
                        onSaved: { diaper in
                            Task { @MainActor in
                                await vm.saveDiaper(diaper)
                                let name = diaper.diaperType == .pee ? "소변" : "대변"
                                toastCenter.show(.init(message: "\(name) 기록 완료!", variant: .success))
                            }
                        }
                    )
                    .environment(container)
                }
                .dsBottomSheet(
                    isPresented: $showFeedingSheet,
                    options: .init(title: "🍼 분유 기록", detents: [.medium, .large])
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
                    options: .init(title: "😴 수면 기록", detents: [.medium])
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
                    options: .init(title: "🎈 터미타임 기록", detents: [.medium, .large])
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
                // 영양제·약(과거 목욕 포함) 생성 시트
                .dsBottomSheet(
                    isPresented: Binding(
                        get: { careCreateCategory != nil },
                        set: { if !$0 { careCreateCategory = nil } }
                    ),
                    options: .init(title: careCreateTitle, detents: [.fraction(0.7), .large])
                ) {
                    if let cat = careCreateCategory {
                        CareInputSheet(
                            isPresented: Binding(
                                get: { careCreateCategory != nil },
                                set: { if !$0 { careCreateCategory = nil } }
                            ),
                            babyId: container.activeBabyId,
                            category: cat,
                            defaultDate: vm.isFocusingPast ? vm.selectedDate : .now,
                            onSaved: { log in
                                Task { @MainActor in
                                    await vm.saveCareLog(log)
                                    toastCenter.show(.init(message: "\(cat.displayName) 기록 완료!", variant: .success))
                                }
                            }
                        )
                        .environment(container)
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.color.surface.color)
            }
        }
        // 네이티브 .sheet 사용 — QuickBarEditSheet는 List+EditMode라 DSBottomSheet의
        // 콘텐츠 ScrollView 안에 넣으면 List가 깨진다(재정렬/삭제/추가 불가). 닫힐 때 바 갱신.
        .sheet(isPresented: $showQuickBarEdit, onDismiss: { quickBarStore.reload() }) {
            QuickBarEditSheet(onDismiss: { showQuickBarEdit = false })
                .environment(\.theme, theme)
                .environment(toastCenter)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            if vm == nil {
                let newVM = HomeViewModel(
                    feedingRepository: container.feedingRepository,
                    babyRepository:    container.babyRepository,
                    sleepRepository:   container.sleepRepository,
                    diaperRepository:  container.diaperRepository,
                    playRepository:    container.playRepository,
                    careLogRepository: container.careLogRepository,
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
            case .pee:                     pendingDiaperType = .pee; showDiaperSheet = true
            case .poo:                     pendingDiaperType = .poo; showDiaperSheet = true
            case .sleep:                   showSleepSheet   = true
            case .play:                    showPlaySheet    = true
            // 과거 날짜: 목욕도 시각 입력이 필요하므로 셋 다 시트로.
            case .bath:                    careCreateCategory = .bath
            case .supplement:              careCreateCategory = .supplement
            case .medicine:                careCreateCategory = .medicine
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
            // 그냥 누르면 즉시 기록(기본 보통/보통/보통). 상세는 행 탭 모달에서 수정.
            Task { @MainActor in
                let msg = await vm.quickSavePoo()
                toastCenter.show(.init(message: msg, variant: .success))
            }
        case .sleep:
            Task { @MainActor in
                let msg = await vm.toggleSleep()
                toastCenter.show(.init(message: msg, variant: .success))
            }
        case .play:
            Task { @MainActor in
                let msg = await vm.recordPlay()   // 즉시 기록(분유처럼 시점만)
                toastCenter.show(.init(message: msg, variant: .success))
            }
        case .bath:
            // 목욕: 원탭 즉시 기록(시점만).
            Task { @MainActor in
                let msg = await vm.quickSaveBath()
                toastCenter.show(.init(message: msg, variant: .success))
            }
        case .supplement:
            careCreateCategory = .supplement   // 이름·용량 시트
        case .medicine:
            careCreateCategory = .medicine     // 이름·용량 시트
        }
    }

    /// 돌봄기록 생성 시트 타이틀.
    private var careCreateTitle: String {
        switch careCreateCategory {
        case .bath:       return "🛁 목욕 기록"
        case .supplement: return "🧴 영양제 기록"
        case .medicine:   return "💊 약 기록"
        case .none:       return "기록"
        }
    }
}

// MARK: - HomeAction

enum HomeAction { case formula, breast, pee, poo, sleep, play, supplement, medicine, bath }

// MARK: - QuickBarStore (@Observable, 선호 보유·구독)

/// BigActionGrid 데이터 소스 — QuickBarSettings 변경을 관찰하고 뷰에 즉시 반영.
@Observable
final class QuickBarStore {
    private(set) var visibleKinds: [QuickButtonKind]

    init() {
        self.visibleKinds = QuickBarSettings.visibleKinds
    }

    /// 편집 시트 닫힘 후 호출 → UserDefaults 최신값 재로드
    func reload() {
        visibleKinds = QuickBarSettings.visibleKinds
    }
}

// MARK: - HomeContentView

private struct HomeContentView: View {
    @Bindable var vm: HomeViewModel
    let quickBarStore: QuickBarStore
    let onAction: (HomeAction) -> Void
    let onEditQuickBar: () -> Void

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

            // 동기화 상태 표시(콜드스타트/오프라인 완충) — 관련 있을 때만 나타남.
            HomeSyncStatusBar()

            if vm.isFocusingPast {
                PastFocusView(vm: vm, quickBarStore: quickBarStore, onAction: onAction)
            } else {
                TodayView(vm: vm, quickBarStore: quickBarStore, onAction: onAction, onEditQuickBar: onEditQuickBar)
            }
        }
        .background(theme.color.surface.color)
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

// MARK: - HomeSyncStatusBar (동기화 상태 완충)

/// 서버 동기화 상태를 홈 상단에 얇게 표시 — "동기화 중"·"오프라인"일 때만 나타난다.
/// 콜드스타트로 웹/타기기 기록이 늦게 뜰 때 "왜 안 뜨지?" 불안을 "진행 중"으로 재프레이밍.
/// server-only(syncCoordinator 없음)·idle이면 아무것도 안 그림.
private struct HomeSyncStatusBar: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.theme) private var theme

    var body: some View {
        if let coordinator = container.syncCoordinator,
           let info = info(for: coordinator.status) {
            HStack(spacing: theme.space.inlineGap) {
                if info.spinning {
                    ProgressView().controlSize(.mini).tint(info.fg)
                } else {
                    Image(systemName: info.icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(info.text)
                    .font(theme.typography.caption)
                Spacer(minLength: 0)
            }
            .foregroundStyle(info.fg)
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(info.bg)
            .transition(.opacity)
            .animation(.easeInOut(duration: theme.motion.fast), value: coordinator.status)
        }
    }

    private struct Info {
        let text: String
        let icon: String
        let spinning: Bool
        let fg: Color
        let bg: Color
    }

    /// idle → nil(숨김). syncing/offline/error만 표시.
    private func info(for status: SyncStatus) -> Info? {
        switch status {
        case .idle:
            return nil
        case .syncing:
            return Info(
                text: "동기화 중…", icon: "arrow.triangle.2.circlepath", spinning: true,
                fg: theme.color.textSecondary.color, bg: theme.color.surfaceSunken.color
            )
        case .offline:
            return Info(
                text: "오프라인 — 기록은 안전하게 저장돼요", icon: "wifi.slash", spinning: false,
                fg: theme.color.statusWarningFg.color, bg: theme.color.statusWarningBg.color
            )
        case .error:
            return Info(
                text: "동기화가 지연되고 있어요 · 곧 다시 시도해요", icon: "exclamationmark.arrow.triangle.2.circlepath",
                spinning: false,
                fg: theme.color.statusWarningFg.color, bg: theme.color.statusWarningBg.color
            )
        }
    }
}

// MARK: - TodayView (고정 상단 그리드 + 여러 날 스크롤 피드)

private struct TodayView: View {
    @Bindable var vm: HomeViewModel
    let quickBarStore: QuickBarStore
    let onAction: (HomeAction) -> Void
    let onEditQuickBar: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // ── 고정 상단: 퀵 버튼 1줄 가로 스크롤 ──
            // 좌우 패딩은 스크롤 내부가 담당(full-bleed 스크롤) — 여기선 상하만.
            BigActionGrid(
                visibleKinds: quickBarStore.visibleKinds,
                hasActiveSleep: vm.activeSleepSession != nil,
                onAction: onAction,
                onEditTapped: onEditQuickBar,
                showEditChip: true
            )
            .padding(.top, theme.space.sm)
            .padding(.bottom, theme.space.sm)
            .background(theme.color.surface.color)
            .overlay(alignment: .bottom) {
                Rectangle().fill(theme.color.divider.color).frame(height: 1)
            }

            // ── 육퇴 배너(오후 5시 이후 또는 이미 육퇴중일 때만) ──
            if showNightOffBar {
                nightOffBar
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
            .background(theme.color.surface.color)
        }
        .onAppear { vm.loadReminderState() }   // 설정 화면 다녀온 뒤 육퇴/알림 상태 갱신
    }

    /// 육퇴 배너 표시 조건: 알림 켜짐 + (오후 5시 이후 또는 이미 육퇴중).
    private var showNightOffBar: Bool {
        guard vm.reminderEnabled else { return false }
        let hour = Calendar.kst.component(.hour, from: Date())
        return hour >= 17 || vm.nightOffActive
    }

    /// 육퇴 배너 — 탭하면 오늘 밤 수유 알림 끔/켬. 다음 수유 기록 시 자동 복귀.
    /// 육퇴중 = 연보라 배경 + 오른쪽 별.
    private var nightOffBar: some View {
        // 육퇴중 연보라 팔레트(라이트/다크 대응).
        let activeBg = DynamicColor(light: PrimitiveColor.purple100,
                                    dark: PrimitiveColor.purple500.opacity(0.28)).color
        let activeFg = DynamicColor(light: PrimitiveColor.purple700,
                                    dark: PrimitiveColor.purple100).color
        return Button {
            vm.toggleNightOff()
        } label: {
            HStack(spacing: theme.space.sm) {
                Image(systemName: vm.nightOffActive ? "moon.zzz.fill" : "moon.zzz")
                Text(vm.nightOffActive
                     ? "육퇴 중 · 수유 알림 꺼짐 — 탭하면 다시 켜기"
                     : "육퇴 · 오늘 밤 수유 알림 끄기")
                    .font(theme.typography.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                if vm.nightOffActive {
                    Image(systemName: "star.fill").font(.system(size: 13))
                }
            }
            .foregroundStyle(vm.nightOffActive ? activeFg : theme.color.textSecondary.color)
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.vertical, theme.space.sm)
            .frame(maxWidth: .infinity)
            .background(vm.nightOffActive ? activeBg : theme.color.surfaceSunken.color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PastFocusView (과거 날짜 단일 일자)

private struct PastFocusView: View {
    @Bindable var vm: HomeViewModel
    let quickBarStore: QuickBarStore
    let onAction: (HomeAction) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: theme.space.sm) {
                // 과거 기록 안내 배너 — 웹정합: "오늘로" 버튼 없음(헤더 날짜네비로 복귀).
                HStack(spacing: theme.space.xs) {
                    Text("📅")
                    Text("\(vm.selectedDate.relativeLabel)에 기록 중 · 버튼을 누르면 시각을 입력해요")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.color.statusWarningFg.color)
                    Spacer()
                }
                .padding(.horizontal, theme.space.componentPaddingX)
                .padding(.vertical, theme.space.sm)
                .background(theme.color.statusWarningBg.color)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous))

                // 과거 포커스 모드: 편집 칩/롱프레스 진입점 숨김(스펙 §5.5)
                BigActionGrid(
                    visibleKinds: quickBarStore.visibleKinds,
                    hasActiveSleep: false,
                    onAction: onAction,
                    onEditTapped: {},
                    showEditChip: false
                )
            }
            .padding(.horizontal, theme.space.screenPaddingX)
            .padding(.vertical, theme.space.sm)
            .background(theme.color.surface.color)
            .overlay(alignment: .bottom) {
                Rectangle().fill(theme.color.divider.color).frame(height: 1)
            }

            ScrollView {
                DayTimelineSection(vm: vm, day: Calendar.kst.startOfDay(for: vm.selectedDate))
                    .padding(.bottom, theme.space.lg)
            }
            .background(theme.color.surface.color)
        }
    }
}

// MARK: - DateSectionHeader (오늘/어제/그제/"N월 N일 (요일)")

private struct DateSectionHeader: View {
    let day: Date
    @Environment(\.theme) private var theme

    private var isToday: Bool { Calendar.kst.isDateInToday(day) }

    private var isRelative: Bool {
        let cal = Calendar.kst
        if cal.isDateInToday(day) || cal.isDateInYesterday(day) { return true }
        if let two = cal.date(byAdding: .day, value: -2, to: cal.startOfDay(for: Date())),
           cal.isDate(day, inSameDayAs: two) { return true }
        return false
    }

    private var label: String {
        let cal = Calendar.kst
        if cal.isDateInToday(day)     { return "오늘" }
        if cal.isDateInYesterday(day) { return "어제" }
        if let two = cal.date(byAdding: .day, value: -2, to: cal.startOfDay(for: Date())),
           cal.isDate(day, inSameDayAs: two) { return "그제" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.timeZone = .kst
        fmt.dateFormat = "M월 d일 (E)"
        return fmt.string(from: day)
    }

    /// 웹정합: 오늘/어제/그제 옆 작은 YYYY-MM-DD 부가 표기(10pt gray-400).
    private var isoDate: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .kst
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: day)
    }

    var body: some View {
        HStack(spacing: theme.space.xs) {
            Text(label)
                .font(theme.typography.captionStrong)
                .foregroundStyle(isToday ? theme.color.primary.color : theme.color.textSecondary.color)
            if isRelative {
                Text(isoDate)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.color.textTertiary.color)
            }
            Spacer()
        }
        .padding(.horizontal, theme.space.screenPaddingX)
        .padding(.vertical, theme.space.sm)
        .frame(maxWidth: .infinity)
        // 날짜 헤더(오늘/어제)만 회색 band — 기록영역/페이지는 흰색이라 구분됨.
        .background(theme.color.background.color)
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
    @State private var editCareLog: CareLog? = nil

    private var isToday: Bool { Calendar.kst.isDateInToday(day) }

    /// 타임라인 탭 → 돌봄기록이면 CareInputSheet, 아니면 RecordEditSheet.
    private func startEdit(_ item: TimelineItem) {
        if let c = vm.careLog(for: item, on: day) {
            editCareLog = c
        } else {
            editRecord = vm.editableRecord(for: item, on: day)
        }
    }

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
                    let rowVariant: TimelineRowVariant = (isToday && index == 0) ? .highlighted : .normal
                    TimelineGroupView(
                        variant: rowVariant
                    ) {
                        TimelineItemRow(
                            time:     item.time.timeString,
                            label:    item.label,
                            memo:     item.memo,
                            dotColor: theme.color.solid(for: item.domainKind).color,
                            variant:  rowVariant,
                            onEdit:   { startEdit(item) }
                        )
                        // LazyVStack 에서는 swipeActions 가 동작하지 않으므로
                        // 길게 눌러 편집/삭제하는 컨텍스트 메뉴로 제공.
                        .contextMenu {
                            Button {
                                startEdit(item)
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
                    // 좌우 패딩·하이라이트는 그룹 내부가 담당(웹처럼 전폭). 이중 패딩 금지.

                    if index < items.count - 1 {
                        Divider()   // 웹 divide-y — 전폭 얇은 구분선
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
            options: .init(title: editSheetTitle, detents: [.fraction(0.62), .large])
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
        // 돌봄기록 편집(목욕·영양제·약)
        .dsBottomSheet(
            isPresented: Binding(
                get: { editCareLog != nil },
                set: { if !$0 { editCareLog = nil } }
            ),
            options: .init(title: careEditTitle, detents: [.fraction(0.7), .large])
        ) {
            if let log = editCareLog {
                CareInputSheet(
                    isPresented: Binding(
                        get: { editCareLog != nil },
                        set: { if !$0 { editCareLog = nil } }
                    ),
                    babyId: log.babyId,
                    category: log.category,
                    editing: log,
                    onSaved: { updated in
                        Task { @MainActor in
                            await vm.updateCareLog(updated)
                            toastCenter.show(.init(message: "\(updated.category.displayName) 수정 완료!", variant: .success))
                        }
                    },
                    onDelete: {
                        vm.delete(TimelineItem(from: log), on: day)
                    }
                )
            }
        }
    }

    /// 돌봄기록 편집 시트 타이틀.
    private var careEditTitle: String {
        guard let c = editCareLog else { return "수정" }
        return "\(c.category.emoji) \(c.category.displayName) 수정"
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

// MARK: - BigActionGrid (데이터 구동 1줄 가로 스크롤)

private struct BigActionGrid: View {
    /// 표시할 kind 배열(순서=배열순서). QuickBarStore.visibleKinds 전달.
    let visibleKinds:   [QuickButtonKind]
    let hasActiveSleep: Bool
    let onAction:       (HomeAction) -> Void
    /// "편집" 칩 탭 → 편집 시트 오픈
    let onEditTapped:   () -> Void
    /// 과거 포커스 모드에선 false(편집 진입점 숨김, 스펙 §5.5)
    let showEditChip:   Bool

    @Environment(\.theme) private var theme

    /// 렌더링할 QuickAction 목록 (활성 수면 자동 포함)
    private var actions: [QuickAction] {
        QuickActionCatalog.orderedActions(visibleKinds: visibleKinds, hasActiveSleep: hasActiveSleep)
    }

    var body: some View {
        // 1줄 가로 스크롤 — 화면 폭보다 넓으면 옆으로 스크롤(끝단 살짝 보이게 full-bleed).
        // 롱프레스 → 편집 시트 (보조 진입점, 스펙 §3.3)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.space.sm) {
                ForEach(actions, id: \.kind) { qa in
                    let isActive = qa.isSessionToggle && hasActiveSleep
                    let label    = (qa.kind == .sleep && hasActiveSleep) ? "수면 종료" : qa.label
                    BigActionButton(
                        emoji:    qa.emoji,
                        label:    label,
                        kind:     qa.kind,
                        isActive: isActive
                    ) { onAction(qa.action) }
                }

                // 편집 칩 — 스크롤 맨 끝 고정(오늘 뷰만 표시)
                if showEditChip {
                    EditQuickBarChip(action: onEditTapped)
                }
            }
            .padding(.horizontal, theme.space.screenPaddingX)   // 스크롤 내부 좌우 여백(full-bleed 스크롤)
        }
        // 롱프레스 진입점 제거 — 버튼 누름과 충돌·오작동 위험. 편집은 "편집" 칩으로.
    }
}

// MARK: - EditQuickBarChip (바 끝 "편집" 칩)

private struct EditQuickBarChip: View {
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        // "+" 아이콘 버튼 — 배경 없음, 점선 테두리만.
        // 높이는 BigActionButton과 픽셀 동일: 같은 콘텐츠 구조(이모지20+라벨11+xs간격)를
        // 숨김 미러로 깔고 동일 폭(72)·상하패딩(12)을 적용 → maxHeight 늘어남 문제 제거.
        Button(action: action) {
            ZStack {
                VStack(spacing: theme.space.xs) {
                    Text("＋").font(.system(size: 20))
                    Text("편집").font(.system(size: 11, weight: .semibold))
                }
                .hidden()   // 높이 기준용(옆 버튼과 동일 구조)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.color.textSecondary.color)
            }
            .frame(width: 72)                              // 옆 퀵버튼과 동일 폭
            .padding(.vertical, theme.space.stackGapMd)    // py-3=12, 옆 버튼과 동일
            .background(
                RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                    .strokeBorder(theme.color.borderStrong.color,
                                  style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            )
        }
        .buttonStyle(QuickPressButtonStyle())
        .accessibilityLabel("빠른기록 편집")
    }
}

// MARK: - BigActionButton

private struct BigActionButton: View {
    let emoji: String
    let label: String
    let kind:  QuickButtonKind
    var isActive: Bool = false
    let action: () -> Void

    @Environment(\.theme) private var theme

    // 웹 BigActionGrid.tsx: idle=bg{50}/border{100}/text{700}, active=bg{100}/border{300}/text{800}.
    private var palette: QuickButtonColors { theme.color.quickButton(kind) }

    var body: some View {
        Button(action: action) {
            // 웹: flex-col gap-1(4pt), py-3(12pt), rounded-xl(12), border 1pt, active:scale-95.
            VStack(spacing: theme.space.xs) {
                Text(emoji).font(.system(size: 20))       // 웹 text-xl = 20pt
                Text(label)
                    .font(.system(size: 11, weight: .semibold))  // 웹 text-[11px] font-semibold
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle((isActive ? palette.activeText : palette.idleText).color)
            .frame(width: 72)   // 가로 스크롤: 고정 폭(그리드 flexible 대신)
            .padding(.vertical, theme.space.stackGapMd)   // py-3 = 12pt
            .background(
                RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                    .fill((isActive ? palette.activeBg : palette.idleBg).color)
            )
            .overlay(
                // strokeBorder: 테두리를 프레임 '안쪽'에 그려 스크롤뷰 클리핑에 안 잘림.
                // (.stroke는 경로 중앙 정렬이라 바깥 0.5pt가 잘려 버튼마다 테두리가 들쭉날쭉했음)
                RoundedRectangle(cornerRadius: theme.radius.control, style: .continuous)
                    .strokeBorder((isActive ? palette.activeBorder : palette.idleBorder).color, lineWidth: 1)
            )
        }
        // 누름 효과는 ButtonStyle로 — DragGesture를 안 써야 가로 ScrollView가 스크롤됨.
        .buttonStyle(QuickPressButtonStyle())
    }
}

// MARK: - QuickPressButtonStyle (누름 스케일 — 스크롤 제스처 비차단)

/// 퀵버튼 누름 시 scale 0.95. 별도 DragGesture 없이 ButtonStyle의 isPressed만 사용해
/// 가로 ScrollView의 팬 제스처를 막지 않는다(가로 스크롤 정상 동작).
private struct QuickPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
