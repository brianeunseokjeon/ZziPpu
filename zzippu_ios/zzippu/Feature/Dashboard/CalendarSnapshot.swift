// Feature/Dashboard/CalendarSnapshot.swift
// 달력 SWR(stale-while-revalidate) 디스크 캐시용 월별 스냅샷 모델.
// volumes-only 원칙: 네트워크/DB 원천인 "수유 총량"만 저장.
// 검진 데코는 생일 기반 순수계산이라 캐시 금지 → hydrate 시 항상 재계산·합성.

import Foundation

/// 스냅샷에 담는 하루 총 수유량 (DateVolume 의 Codable 미러).
/// DateVolume 자체는 Domain(Foundation-only, non-Codable)이라 저장용 값을 별도 정의.
struct DateVolumeSnapshot: Codable, Sendable {
    let day: Date        // KST 자정
    let totalMl: Int
}

/// 특정 월(月)의 마지막 성공 수유 총량 스냅샷.
/// MonthCalendarModel 통째 저장 금지 — volumes 만 저장하고 나머지는 재계산.
struct CalendarMonthSnapshot: Codable, Sendable {
    let month: Date                       // 해당 월 첫날(KST 자정)
    let volumes: [DateVolumeSnapshot]     // 42칸 범위 dailyTotals 결과
    let savedAt: Date
}
