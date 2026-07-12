// Domain/Entities/Calendar/DateVolume.swift
// dailyTotals API 결과 단위 — KST 자정 기준 날짜 + 총 수유량.

import Foundation

struct DateVolume {
    let day: Date     // KST 자정 기준
    let totalMl: Int
}
