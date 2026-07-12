// Domain/UseCases/ComputeFeedingTrendUseCase.swift
// 수유량 추세 집계 — feeding 기록 + dayCount(7/14) → KST 일별 수유량(ml) 배열.
// 순수 로직(Repository 비의존, 입력만) · 테스트 가능. Foundation only.
//
// 웹 TrendsDashboard 정합:
//   • 하루 수유량 = 해당 KST 일(day)의 amountMl 합산.
//   • 기록이 하나도 없는 날은 value = nil(웹의 "데이터 없음" — 흐린 막대).
//   • 요일 라벨 포함(일/월/화/…), 오늘 포함 최근 dayCount일 오름차순.

import Foundation

// MARK: - FeedingTrendDay

/// 수유 추세 일별 집계 한 점. value=nil이면 그날 기록 없음.
struct FeedingTrendDay: Equatable, Sendable {
    let date: Date        // KST 자정(startOfDay)
    let totalMl: Double?  // 그날 amountMl 합산. 기록 없으면 nil.
    let weekdayLabel: String  // 요일 한 글자(일/월/화/수/목/금/토)
}

// MARK: - ComputeFeedingTrendUseCase

struct ComputeFeedingTrendUseCase {

    private let calendar = Calendar.kst

    private static let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    /// feeding 기록 + dayCount → KST 일별 수유량 ml 배열(오늘 포함, 오름차순).
    /// - Parameters:
    ///   - feedings: 조회된 수유 기록(범위 밖 항목이 섞여도 무방 — 내부에서 필터).
    ///   - dayCount: 7 또는 14.
    ///   - anchorDate: 기준일(오늘). 기본 .now.
    func callAsFunction(
        feedings: [Feeding],
        dayCount: Int,
        anchorDate: Date = .now
    ) -> [FeedingTrendDay] {
        let days = max(1, dayCount)
        let startDate = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -(days - 1), to: anchorDate) ?? anchorDate
        )
        let endDate = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: anchorDate) ?? anchorDate
        )

        // 일별 합산(기록 있는 날만 키 존재 → nil/값 구분 가능).
        var sums: [Date: Double] = [:]
        for f in feedings {
            let day = calendar.startOfDay(for: f.startedAt)
            guard day >= startDate && day < endDate else { continue }
            sums[day, default: 0] += Double(f.amountMl ?? 0)
        }

        // 연속 날짜 축 생성(빈 날 nil).
        var result: [FeedingTrendDay] = []
        var cursor = startDate
        while cursor < endDate {
            let weekdayIndex = calendar.component(.weekday, from: cursor) - 1
            let label = Self.weekdaySymbols[max(0, min(6, weekdayIndex))]
            result.append(
                FeedingTrendDay(
                    date: cursor,
                    totalMl: sums[cursor],   // 키 없으면 nil = 데이터 없음
                    weekdayLabel: label
                )
            )
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? endDate
        }
        return result
    }

    /// 유효 데이터가 있는 날의 평균 ml(권장/표시용). 없으면 0.
    func average(of days: [FeedingTrendDay]) -> Double {
        let values = days.compactMap(\.totalMl)
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
