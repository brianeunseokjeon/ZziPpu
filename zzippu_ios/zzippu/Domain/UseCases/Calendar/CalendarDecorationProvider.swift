// Domain/UseCases/Calendar/CalendarDecorationProvider.swift
// 달력 데코레이션 플러그인 추상화 — 확장 인터페이스.
// 새 도메인(수면·예방접종 등) 추가 시 이 프로토콜 구현 1개 + providers 배열 등록만.

import Foundation

/// 날짜 배열에 대해 데코레이션을 산출하는 플러그인 지점.
/// 지금 2개 구현: FeedingVolumeDecorationProvider, CheckupDecorationProvider.
protocol CalendarDecorationProvider {
    var kind: CalendarDecorationKind { get }

    /// 주어진 달력 날짜 배열에 대한 데코레이션 목록 반환.
    /// - Parameters:
    ///   - days: 그 달 42칸의 KST 자정 Date 배열
    ///   - baby: 아기 (생일·ID 필요)
    /// - Returns: 날짜별 데코레이션 배열 (순서·중복 무관, 오케스트레이터가 머지)
    func decorations(forMonthDays days: [Date], baby: Baby) async throws -> [CalendarDayDecoration]
}
