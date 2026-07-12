// Domain/UseCases/Calendar/ComputeCheckupScheduleUseCase.swift
// 영유아 건강검진 8차 창 계산 — 순수 Domain UseCase (네트워크 0).
// KST Calendar 기준. 확정 계산식(재검증됨):
//   1차: start=생일+14일, end=생일+35일
//   2~8차: start=생일+A개월, end=생일+(B+1)개월−1일
//
// 검증:
//   2026-04-22생 → 2차: 2026-08-22~2026-11-21 ✓
//                   3차: 2027-01-22~2027-05-21 ✓

import Foundation

// MARK: - CheckupWindow

/// 영유아 검진 한 차수의 기간 창.
struct CheckupWindow {
    let order: Int    // 1~8
    let start: Date   // 검진 가능 시작일 (KST 자정)
    let end:   Date   // 검진 가능 마지막 날 (KST 자정)

    var orderLabel: String { "\(order)차" }

    func contains(_ date: Date) -> Bool {
        let cal = Calendar.kst
        let d = cal.startOfDay(for: date)
        return d >= cal.startOfDay(for: start) && d <= cal.startOfDay(for: end)
    }

    /// 오늘 기준 D-day (양수=미래, 0=시작일, 음수=과거)
    func dDay(from today: Date) -> Int {
        let cal = Calendar.kst
        let todayStart = cal.startOfDay(for: today)
        let startDay   = cal.startOfDay(for: start)
        return cal.dateComponents([.day], from: todayStart, to: startDay).day ?? 0
    }

    /// 마감까지 남은 날(오늘 기준)
    func daysUntilEnd(from today: Date) -> Int {
        let cal = Calendar.kst
        let todayStart = cal.startOfDay(for: today)
        let endDay     = cal.startOfDay(for: end)
        return cal.dateComponents([.day], from: todayStart, to: endDay).day ?? 0
    }
}

// MARK: - ComputeCheckupScheduleUseCase

/// 생일 → 영유아 검진 8차 창 배열 (순수 계산, 상태·네트워크 없음).
struct ComputeCheckupScheduleUseCase {

    /// 생일로부터 8차 검진 창 전부 계산.
    /// - Parameter birthDate: 아기 생일 (시각 무관 — KST 날짜만 사용)
    /// - Returns: [CheckupWindow] (1차~8차, 순서대로)
    func callAsFunction(birthDate: Date) -> [CheckupWindow] {
        let cal = Calendar.kst
        let birth = cal.startOfDay(for: birthDate)

        // 1차: 생일+14일 ~ 생일+35일 (일 기준)
        let w1start = cal.date(byAdding: .day, value: 14, to: birth)!
        let w1end   = cal.date(byAdding: .day, value: 35, to: birth)!

        // 2~8차: start=생일+A개월, end=생일+(B+1)개월−1일
        // (A, B) = (4,6), (9,12), (18,24), (30,36), (42,48), (54,60), (66,71)
        // end 공식: 생일 + (B+1)개월 → 그 날 − 1일
        // 주의: 71개월은 B+1=72개월
        let ranges: [(a: Int, bPlus1: Int)] = [
            (4, 7), (9, 13), (18, 25), (30, 37), (42, 49), (54, 61), (66, 72)
        ]

        var windows: [CheckupWindow] = [
            CheckupWindow(order: 1, start: w1start, end: w1end)
        ]

        for (idx, range) in ranges.enumerated() {
            let order  = idx + 2
            let start  = cal.date(byAdding: .month, value: range.a, to: birth)!
            let endBase = cal.date(byAdding: .month, value: range.bPlus1, to: birth)!
            let end    = cal.date(byAdding: .day, value: -1, to: endBase)!
            windows.append(CheckupWindow(order: order, start: start, end: end))
        }

        return windows
    }

    /// 오늘 기준 다가오는(또는 진행 중인) 가장 가까운 검진 창 1개.
    /// - Returns: 진행 중 → .inProgress, 미래 가장 가까운 → .upcoming, 없음 → .none
    func nextWindow(birthDate: Date, today: Date) -> CheckupBannerInfo {
        let windows = callAsFunction(birthDate: birthDate)
        let cal = Calendar.kst
        let todayStart = cal.startOfDay(for: today)

        // 진행 중 먼저
        for w in windows {
            let s = cal.startOfDay(for: w.start)
            let e = cal.startOfDay(for: w.end)
            if todayStart >= s && todayStart <= e {
                let daysLeft = cal.dateComponents([.day], from: todayStart, to: e).day ?? 0
                return .inProgress(order: w.order, daysLeft: daysLeft, start: w.start, end: w.end)
            }
        }
        // 미래 중 가장 가까운
        for w in windows {
            let s = cal.startOfDay(for: w.start)
            if s > todayStart {
                let dDay = cal.dateComponents([.day], from: todayStart, to: s).day ?? 0
                return .upcoming(order: w.order, dDay: dDay, start: w.start, end: w.end)
            }
        }
        return .none
    }
}
