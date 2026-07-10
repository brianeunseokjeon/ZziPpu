// Domain/UseCases/ComputeTrendUseCase.swift
// 기간별 추세 집계 (일/주/월) — 순수 로직, 테스트 가능.
// 구 웹 trendCalc 개념을 UseCase 으로 분리.
// Foundation only — SwiftUI/SwiftData import 금지.

import Foundation

// MARK: - TrendRange

enum TrendRange: String, CaseIterable, Identifiable {
    case day   = "일"
    case week  = "주"
    case month = "월"

    var id: String { rawValue }

    /// 기준 날짜 이전 n일 범위 (오늘 포함)
    var days: Int {
        switch self {
        case .day:   return 1
        case .week:  return 7
        case .month: return 30
        }
    }
}

// MARK: - ComputeTrendUseCase

struct ComputeTrendUseCase {

    private let calendar = Calendar.current

    // MARK: - Feeding Trend (일별 총 ml)

    func feedingTrend(
        feedings: [Feeding],
        range: TrendRange,
        anchorDate: Date = .now
    ) -> [MetricPoint] {
        bucketByDay(
            items: feedings,
            dateKeyPath: \.startedAt,
            valueKeyPath: { Double($0.amountMl ?? 0) },
            range: range,
            anchorDate: anchorDate
        )
    }

    // MARK: - Sleep Trend (일별 총 분)

    func sleepTrend(
        sleeps: [SleepRecord],
        range: TrendRange,
        anchorDate: Date = .now
    ) -> [MetricPoint] {
        bucketByDay(
            items: sleeps,
            dateKeyPath: \.startedAt,
            valueKeyPath: { Double($0.durationMinutes ?? 0) },
            range: range,
            anchorDate: anchorDate
        )
    }

    // MARK: - Diaper Trend (일별 횟수)

    func diaperTrend(
        diapers: [DiaperRecord],
        range: TrendRange,
        anchorDate: Date = .now
    ) -> [MetricPoint] {
        bucketByDay(
            items: diapers,
            dateKeyPath: \.recordedAt,
            valueKeyPath: { _ in 1.0 },
            range: range,
            anchorDate: anchorDate
        )
    }

    // MARK: - Play Trend (일별 총 분)

    func playTrend(
        plays: [PlayRecord],
        range: TrendRange,
        anchorDate: Date = .now
    ) -> [MetricPoint] {
        bucketByDay(
            items: plays,
            dateKeyPath: \.startedAt,
            valueKeyPath: { Double($0.durationMinutes ?? 0) },
            range: range,
            anchorDate: anchorDate
        )
    }

    // MARK: - Average

    func average(of points: [MetricPoint]) -> Double {
        guard !points.isEmpty else { return 0 }
        return points.map(\.value).reduce(0, +) / Double(points.count)
    }

    // MARK: - Private Helpers

    private func bucketByDay<T>(
        items: [T],
        dateKeyPath: KeyPath<T, Date>,
        valueKeyPath: (T) -> Double,
        range: TrendRange,
        anchorDate: Date
    ) -> [MetricPoint] {
        let startDate = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -(range.days - 1), to: anchorDate) ?? anchorDate
        )
        let endDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: anchorDate) ?? anchorDate)

        // 날짜별 버킷 초기화
        var buckets: [Date: Double] = [:]
        var cursor = startDate
        while cursor < endDate {
            buckets[cursor] = 0
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? endDate
        }

        // 집계
        for item in items {
            let itemDate = calendar.startOfDay(for: item[keyPath: dateKeyPath])
            guard itemDate >= startDate && itemDate < endDate else { continue }
            buckets[itemDate, default: 0] += valueKeyPath(item)
        }

        // 정렬 후 MetricPoint 변환
        return buckets.sorted { $0.key < $1.key }
            .map { date, value in MetricPoint(date: date, value: value) }
    }
}

// MARK: - Insight Text Helpers

extension ComputeTrendUseCase {

    /// 수유 추세 인사이트 문구 생성
    func feedingInsight(avg: Double, range: TrendRange) -> String {
        let avgInt = Int(avg)
        guard avgInt > 0 else { return "\(range.rawValue) 평균 데이터 없음" }
        return "\(range.rawValue) 평균 \(avgInt)ml"
    }

    /// 수면 추세 인사이트 문구
    func sleepInsight(avg: Double, range: TrendRange) -> String {
        let totalMin = Int(avg)
        guard totalMin > 0 else { return "\(range.rawValue) 평균 데이터 없음" }
        let h = totalMin / 60; let m = totalMin % 60
        let timeStr = h > 0 ? "\(h)시간 \(m > 0 ? "\(m)분" : "")" : "\(m)분"
        return "\(range.rawValue) 평균 수면 \(timeStr)"
    }

    /// 기저귀 추세 인사이트
    func diaperInsight(avg: Double, range: TrendRange) -> String {
        guard avg > 0 else { return "\(range.rawValue) 평균 데이터 없음" }
        return String(format: "\(range.rawValue) 평균 %.1f회", avg)
    }

    /// 놀이 추세 인사이트
    func playInsight(avg: Double, range: TrendRange) -> String {
        let totalMin = Int(avg)
        guard totalMin > 0 else { return "\(range.rawValue) 평균 데이터 없음" }
        return "\(range.rawValue) 평균 놀이 \(totalMin)분"
    }
}
