//
//  zzippuTests.swift
//  zzippuTests
//

import XCTest
@testable import zzippu

final class zzippuTests: XCTestCase {

    // MARK: - 자정 롤오버 로직 (rolloverPrependDays)

    private let cal = Calendar.kst

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        c.timeZone = .kst
        return cal.startOfDay(for: cal.date(from: c)!)
    }

    /// 하루 넘김: 어제가 top이고 오늘이 새 날 → [오늘] 추가.
    func testRollover_oneDay() {
        let today = day(2026, 7, 24)
        let yesterday = day(2026, 7, 23)
        let result = HomeViewModel.rolloverPrependDays(newToday: today, currentTop: yesterday, calendar: cal)
        XCTAssertEqual(result, [today], "어제→오늘 넘김 시 오늘 하루만 앞에 추가돼야 함")
    }

    /// 이틀 이상 켜둔 경우: 22일이 top인데 24일이 오늘 → [24, 23] 연속 추가(gap 없음).
    func testRollover_multiDay_noGap() {
        let top = day(2026, 7, 22)
        let today = day(2026, 7, 24)
        let result = HomeViewModel.rolloverPrependDays(newToday: today, currentTop: top, calendar: cal)
        XCTAssertEqual(result, [day(2026, 7, 24), day(2026, 7, 23)], "중간 날짜까지 연속 추가돼야 함")
    }

    /// 자정 안 넘김(오늘==top): 추가 없음(no-op).
    func testRollover_sameDay_empty() {
        let today = day(2026, 7, 24)
        let result = HomeViewModel.rolloverPrependDays(newToday: today, currentTop: today, calendar: cal)
        XCTAssertTrue(result.isEmpty, "같은 날이면 추가 없음")
    }

    /// 방어: newToday < top(비정상)이면 빈 배열.
    func testRollover_past_empty() {
        let result = HomeViewModel.rolloverPrependDays(newToday: day(2026, 7, 22),
                                                       currentTop: day(2026, 7, 24), calendar: cal)
        XCTAssertTrue(result.isEmpty)
    }

    /// 월 경계 넘김: 7/31 → 8/1.
    func testRollover_monthBoundary() {
        let result = HomeViewModel.rolloverPrependDays(newToday: day(2026, 8, 1),
                                                       currentTop: day(2026, 7, 31), calendar: cal)
        XCTAssertEqual(result, [day(2026, 8, 1)], "월 경계도 정상 처리")
    }
}
