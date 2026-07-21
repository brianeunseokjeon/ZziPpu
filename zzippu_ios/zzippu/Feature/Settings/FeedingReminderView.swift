// Feature/Settings/FeedingReminderView.swift
// 수유 로컬 알림 설정 화면.
// - 활성 토글(켤 때 권한 요청)
// - 모드 전환: 고정 시간 / 간격 (하나만 활성)
// - 고정: 시각들 추가/삭제, 각 시각 리드타임 전 알림(매일 반복)
// - 간격: 2~4.5시간 선택, 마지막 수유 + 간격, 리드타임 전 알림
// - 리드타임(10/20/30/60분) 공통
// 변경 시마다 저장 + 알림 재조정(container.refreshFeedingReminders()).

import SwiftUI

struct FeedingReminderView: View {

    @Environment(AppContainer.self) private var container
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.theme) private var theme

    @State private var settings = FeedingReminderSettings.load()
    @State private var lastFeedingAt: Date? = nil
    @State private var showingTimePicker = false
    @State private var newTime = Date()
    @State private var showPermissionAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {

                // 활성 토글
                Toggle(isOn: $settings.enabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("수유 알림").font(theme.typography.bodyStrong)
                        Text("예정 시각 전에 미리 알려드려요")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.color.textTertiary.color)
                    }
                }
                .tint(theme.color.primary.color)

                if settings.enabled {
                    modeSection
                    if settings.mode == .fixed { fixedSection } else { intervalSection }
                    leadSection
                }
            }
            .padding(theme.space.screenPaddingX)
        }
        .navigationTitle("수유 알림")
        .navigationBarTitleDisplayMode(.inline)
        .task { lastFeedingAt = try? await container.feedingRepository.lastFeeding(babyId: container.activeBabyId)?.startedAt }
        // 활성화하는 순간 권한 요청(거부 시 되돌림).
        .onChange(of: settings.enabled) { _, isOn in
            if isOn {
                Task {
                    let granted = await FeedingNotificationScheduler.requestAuthorization()
                    if !granted { settings.enabled = false; showPermissionAlert = true }
                }
            }
        }
        // 어떤 설정이든 바뀌면 저장 + 재조정.
        .onChange(of: settings) { _, new in
            new.save()
            container.refreshFeedingReminders()
        }
        .sheet(isPresented: $showingTimePicker) { timePickerSheet }
        .alert("알림 권한이 필요해요", isPresented: $showPermissionAlert) {
            Button("설정 열기") { openSettings() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("설정 > 알림에서 먹놀잠 알림을 허용해 주세요.")
        }
    }

    // MARK: - 모드 전환

    private var modeSection: some View {
        Picker("모드", selection: $settings.mode) {
            Text("고정 시간").tag(FeedingReminderSettings.Mode.fixed)
            Text("간격").tag(FeedingReminderSettings.Mode.interval)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 고정 시간

    private var fixedSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("수유 시각")
                .font(theme.typography.captionStrong)
                .foregroundStyle(theme.color.textSecondary.color)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 84), spacing: theme.space.sm)],
                alignment: .leading, spacing: theme.space.sm
            ) {
                ForEach(settings.fixedTimes, id: \.self) { t in
                    HStack(spacing: 4) {
                        Text(FeedingReminderSettings.hourMinuteLabel(minutesOfDay: t))
                            .font(theme.typography.body)
                        Button {
                            settings.fixedTimes.removeAll { $0 == t }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(theme.color.textTertiary.color)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, theme.space.sm)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: theme.radius.control).fill(theme.color.surfaceSunken.color))
                }

                Button { newTime = Date(); showingTimePicker = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("추가")
                    }
                    .font(theme.typography.body)
                    .foregroundStyle(theme.color.primary.color)
                    .padding(.horizontal, theme.space.sm)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radius.control)
                            .strokeBorder(theme.color.borderStrong.color, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    )
                }
                .buttonStyle(.plain)
            }

            Text("각 시각 \(settings.leadMinutes)분 전에 매일 알림이 와요.")
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textTertiary.color)
        }
    }

    private var timePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker("시각", selection: $newTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                Spacer()
            }
            .padding()
            .navigationTitle("시각 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { showingTimePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") { addFixedTime(); showingTimePicker = false }
                }
            }
        }
        .presentationDetents([.height(320)])
    }

    // MARK: - 간격

    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("수유 간격")
                .font(theme.typography.captionStrong)
                .foregroundStyle(theme.color.textSecondary.color)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                ForEach(FeedingReminderSettings.intervalOptions, id: \.self) { m in
                    optionChip(FeedingReminderSettings.intervalLabel(m),
                               selected: settings.intervalMinutes == m) { settings.intervalMinutes = m }
                }
            }

            // 다음 알림 예정 미리보기
            Text(intervalPreview)
                .font(theme.typography.caption)
                .foregroundStyle(theme.color.textTertiary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var intervalPreview: String {
        guard let last = lastFeedingAt else {
            return "수유를 기록하면 마지막 수유 기준으로 다음 알림이 예약돼요."
        }
        let next = last.addingTimeInterval(Double(settings.intervalMinutes) * 60)
        let fire = next.addingTimeInterval(-Double(settings.leadMinutes) * 60)
        return "마지막 수유 \(clock(last)) → 다음 \(clock(next)) 예정, \(clock(fire))에 알림."
    }

    // MARK: - 리드타임

    private var leadSection: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("알림 시점")
                .font(theme.typography.captionStrong)
                .foregroundStyle(theme.color.textSecondary.color)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 12
            ) {
                ForEach(FeedingReminderSettings.leadOptions, id: \.self) { m in
                    optionChip("\(m)분 전", selected: settings.leadMinutes == m) { settings.leadMinutes = m }
                }
            }
        }
    }

    /// 등폭·전폭 채움 커스텀 칩(라운드 축소). DSChip(캡슐) 대체.
    private func optionChip(_ label: String, selected: Bool, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            Text(label)
                .font(theme.typography.captionStrong)
                .foregroundStyle(selected ? theme.color.onPrimary.color : theme.color.textSecondary.color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? theme.color.statusInfoSolid.color : theme.color.surfaceSunken.color)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 조작

    private func addFixedTime() {
        let comps = Calendar.kst.dateComponents([.hour, .minute], from: newTime)
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        guard !settings.fixedTimes.contains(minutes) else { return }
        settings.fixedTimes.append(minutes)
        settings.fixedTimes.sort()
    }

    private func clock(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.calendar = Calendar.kst
        f.timeZone = Calendar.kst.timeZone
        f.dateFormat = "a h:mm"
        return f.string(from: date)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
