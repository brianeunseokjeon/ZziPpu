// Feature/Settings/FeedingReminderSettings.swift
// 수유 로컬 알림 설정 — UserDefaults(JSON) 영속.
// 두 모드는 하나만 활성(전환): 고정 시간(fixed) 또는 간격(interval).

import Foundation

struct FeedingReminderSettings: Codable, Equatable {

    enum Mode: String, Codable, CaseIterable {
        case fixed      // 미리 정한 시각들, 각 시각 leadMinutes 전 알림(매일 반복)
        case interval   // 마지막 수유 + intervalMinutes, leadMinutes 전 알림(수유 때마다 재계산)
    }

    var enabled: Bool = false
    var mode: Mode = .interval
    /// 고정 시간 모드: 하루 중 분 단위 시각(0...1439), 오름차순 유지.
    var fixedTimes: [Int] = [300, 480, 660, 840, 1020, 1200]   // 5·8·11·14·17·20시
    /// 간격 모드: 수유 간격(분). 2~4.5시간 30분 단위 → 120...270.
    var intervalMinutes: Int = 180
    /// 알림을 예정 시각 몇 분 전에 보낼지(10/20/30/60).
    var leadMinutes: Int = 30
    /// 육퇴(오늘 밤 알림 끔). true면 알림 전부 억제. 다음 수유 기록 시 자동 해제.
    var nightOff: Bool = false

    // MARK: - 선택지(정적)

    /// 간격 옵션: 2 ~ 4.5시간, 30분 단위(분).
    static let intervalOptions: [Int] = [120, 150, 180, 210, 240, 270]
    /// 리드타임 옵션(분).
    static let leadOptions: [Int] = [10, 20, 30, 60]

    // MARK: - 표시 헬퍼

    static func hourMinuteLabel(minutesOfDay m: Int) -> String {
        String(format: "%02d:%02d", (m / 60) % 24, m % 60)
    }
    static func intervalLabel(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return m == 0 ? "\(h)시간" : "\(h).5시간"
    }

    // MARK: - 영속

    private static let key = "feeding.reminder.settings"

    static func load() -> FeedingReminderSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(FeedingReminderSettings.self, from: data)
        else { return FeedingReminderSettings() }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
