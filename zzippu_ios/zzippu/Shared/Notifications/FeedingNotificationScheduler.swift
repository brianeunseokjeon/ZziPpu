// Shared/Notifications/FeedingNotificationScheduler.swift
// 수유 로컬 알림 스케줄링 — UNUserNotificationCenter 래퍼.
// 재조정 = 우리 식별자(prefix) 전부 취소 후 설정대로 재등록. (설정/수유/포그라운드 시 호출)

import Foundation
import UserNotifications

enum FeedingNotificationScheduler {

    private static let center = UNUserNotificationCenter.current()
    /// 우리 알림 식별자 접두사 — 취소 시 이 접두사만 걷어낸다(다른 알림 불침해).
    private static let idPrefix = "feeding.reminder."
    private static let intervalId = "feeding.reminder.interval"
    private static func fixedId(_ minutesOfDay: Int) -> String { "feeding.reminder.fixed.\(minutesOfDay)" }

    // MARK: - 권한

    /// 알림 권한 요청. 반환 = 허용 여부.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func isAuthorized() async -> Bool {
        let s = await center.notificationSettings()
        return s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
    }

    // MARK: - 재조정 (취소 후 재등록)

    /// 설정 + 마지막 수유시각으로 알림 전체 재등록.
    /// - lastFeedingAt: 간격 모드 기준(없으면 간격 알림은 다음 수유 기록 때 재계산).
    static func reschedule(_ settings: FeedingReminderSettings,
                           lastFeedingAt: Date?,
                           now: Date = .now) async {
        await cancelAll()
        // 비활성 또는 육퇴 중이면 아무 알림도 걸지 않는다(이미 전부 취소됨).
        guard settings.enabled, !settings.nightOff else { return }

        switch settings.mode {
        case .fixed:
            for time in settings.fixedTimes {
                // (시각 - 리드) → 전날로 넘어가면 wrap. 매일 반복.
                let fire = ((time - settings.leadMinutes) % 1440 + 1440) % 1440
                var comps = DateComponents()
                comps.hour = fire / 60
                comps.minute = fire % 60
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let content = makeContent(
                    body: "수유 시간 \(settings.leadMinutes)분 전이에요 🍼 (\(FeedingReminderSettings.hourMinuteLabel(minutesOfDay: time)) 예정)"
                )
                await add(id: fixedId(time), content: content, trigger: trigger)
            }

        case .interval:
            guard let last = lastFeedingAt else { return }
            let next = last.addingTimeInterval(Double(settings.intervalMinutes) * 60)
            let fireAt = next.addingTimeInterval(-Double(settings.leadMinutes) * 60)
            let secondsFromNow = fireAt.timeIntervalSince(now)
            // 리드 시각이 이미 지났으면 이번 주기는 건너뜀(다음 수유 기록·포그라운드 때 재계산).
            guard secondsFromNow > 0 else { return }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsFromNow, repeats: false)
            let content = makeContent(
                body: "곧 수유 시간이에요 🍼 (\(Self.clock(next)) 예정)"
            )
            await add(id: intervalId, content: content, trigger: trigger)
        }
    }

    /// 우리 식별자 접두사의 대기 알림 전부 취소.
    static func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
    }

    // MARK: - 내부

    private static func makeContent(body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "수유 알림"
        content.body = body
        content.sound = .default
        return content
    }

    private static func add(id: String, content: UNNotificationContent, trigger: UNNotificationTrigger) async {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private static func clock(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.calendar = Calendar.kst
        f.timeZone = Calendar.kst.timeZone
        f.setLocalizedDateFormatFromTemplate("jmm")   // 기기 언어. ko "오후 4:30"
        return f.string(from: date)
    }
}
