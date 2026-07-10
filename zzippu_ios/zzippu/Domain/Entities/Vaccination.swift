// Domain/Entities/Vaccination.swift
// 예방접종 — Foundation only. isOverdue/daysUntil는 저장 안 하는 로컬 computed.

import Foundation

struct Vaccination: Identifiable, Equatable, Sendable {
    let id: UUID
    let babyId: UUID
    let vaccineName: String
    let doseNumber: Int
    var scheduledDate: Date
    var administeredDate: Date?
    var hospitalName: String?
    var memo: String?
    let createdAt: Date

    /// 완료 여부.
    var isAdministered: Bool { administeredDate != nil }

    /// 권장일까지 남은 일수 (오늘 기준). 완료 시 nil.
    /// 양수: 남음, 0: 오늘, 음수: 지남.
    var daysUntil: Int? {
        guard administeredDate == nil else { return nil }
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let target = cal.startOfDay(for: scheduledDate)
        return cal.dateComponents([.day], from: today, to: target).day
    }

    /// 권장일 + grace 기간이 지났는지 (완료 시 false).
    var isOverdue: Bool {
        guard administeredDate == nil else { return false }
        guard let days = daysUntil else { return false }
        return days < -Self.graceDays
    }

    /// 완료도 지연도 아니지만 권장일이 임박(7일 이내).
    var isDueSoon: Bool {
        guard administeredDate == nil, !isOverdue else { return false }
        guard let days = daysUntil else { return false }
        return days <= Self.dueSoonWindowDays
    }

    /// 표준 grace 기간 (권장일을 지나도 이 기간 안엔 '예정'으로 봄).
    static let graceDays = 30
    /// 임박 판정 창.
    static let dueSoonWindowDays = 7
}
