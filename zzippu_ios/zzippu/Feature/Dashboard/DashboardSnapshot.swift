// Feature/Dashboard/DashboardSnapshot.swift
// SWR(stale-while-revalidate) 디스크 캐시용 스냅샷 모델.
// 대시보드 "표시 상태"만 Codable로 담아 마지막 성공 데이터를 콜드스타트 즉시 복원.
// 도메인 엔티티는 이미 Codable(Foundation) 채택 → 별도 DTO 없이 직접 저장(오염 최소화).

import Foundation

/// 대시보드 마지막 성공 상태 스냅샷 (오늘 날짜 한정 저장/복원).
struct DashboardSnapshot: Codable, Sendable {
    let dailySummary:  DailySummary
    let prediction:    FeedingPrediction
    let growthSeries:  [GrowthRecord]
    let sparkFeedings: [Feeding]
    let sparkSleeps:   [SleepRecord]
    let sparkDiapers:  [DiaperRecord]
    let sparkPlays:    [PlayRecord]
    let trendFeedings: [Feeding]
    let activeBaby:    Baby?
    let savedAt:       Date
}
