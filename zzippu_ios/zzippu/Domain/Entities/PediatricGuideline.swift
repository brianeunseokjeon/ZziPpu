// Domain/Entities/PediatricGuideline.swift
// 소아과 권장 가이드 값 객체 — 번들 JSON에서 로드되는 순수 데이터.
// Foundation only — SwiftUI/SwiftData import 금지.
// 출처(source)를 값에 내장해 의학적 신중성 유지.

import Foundation

// MARK: - PediatricGuideline (루트)

/// 연령/체중 파생 권장 범위 묶음. Data 레이어 로더가 번들 JSON → 이 타입으로 디코딩.
struct PediatricGuideline: Equatable, Sendable, Decodable {
    let version: String
    let disclaimer: String
    let feeding: FeedingGuidelineData
    let sleep: [SleepGuidelineBand]
    let diaper: [DiaperGuidelineBand]
    let tummyTime: [TummyTimeBand]
    let sources: GuidelineSources
}

// MARK: - Feeding (체중 파생, 구간 무관)

struct FeedingGuidelineData: Equatable, Sendable, Decodable {
    let mlPerKgMin: Double
    let mlPerKgMax: Double
    let dailyCapMl: Double
    let tolerance: Double
    let source: String
    let note: String

    /// 체중(kg) → 권장 하한(cap 적용).
    func recommendedMin(weightKg: Double) -> Double {
        min(weightKg * mlPerKgMin, dailyCapMl).rounded()
    }

    /// 체중(kg) → 권장 상한(cap 적용).
    func recommendedMax(weightKg: Double) -> Double {
        min(weightKg * mlPerKgMax, dailyCapMl).rounded()
    }
}

// MARK: - 연령 구간 밴드 (months [minM, maxM))

/// 개월 구간 공통 프로토콜 — 구간 조회 헬퍼(`band(forMonths:)`) 재사용.
protocol AgeBand {
    var minM: Int { get }
    var maxM: Int { get }
}

extension Array where Element: AgeBand {
    /// 개월령이 속한 구간 [minM, maxM). 없으면 마지막(상위) 구간 fallback.
    func band(forMonths months: Int) -> Element? {
        first { months >= $0.minM && months < $0.maxM } ?? last
    }
}

struct SleepGuidelineBand: Equatable, Sendable, Decodable, AgeBand {
    let minM: Int
    let maxM: Int
    let minH: Double
    let maxH: Double
    let label: String
}

struct DiaperGuidelineBand: Equatable, Sendable, Decodable, AgeBand {
    let minM: Int
    let maxM: Int
    let peeMin: Int
    let poopMin: Int
    let poopMax: Int
    let label: String
}

struct TummyTimeBand: Equatable, Sendable, Decodable, AgeBand {
    let minM: Int
    let maxM: Int
    let minMin: Int
    let targetMin: Int
}

// MARK: - Sources

struct GuidelineSources: Equatable, Sendable, Decodable {
    let sleep: String
    let diaper: String
    let growth: String
}

// MARK: - WHO 성장 밴드 (성별×지표별 파일)

/// WHO 백분위 밴드 — 이번 슬라이스는 스키마 + 로더 자리 예약(데이터 최소).
struct WHOGrowthTable: Equatable, Sendable, Decodable {
    let metric: String   // "weight" | "height" | "headcirc"
    let sex: String      // "boy" | "girl"
    let unit: String
    let rows: [WHOGrowthRow]
}

struct WHOGrowthRow: Equatable, Sendable, Decodable {
    let m: Int           // 월령
    let p3: Double
    let p15: Double
    let p50: Double
    let p85: Double
    let p97: Double
}

/// WHO 파일 선택 키.
enum WHOGrowthMetric: String, Sendable {
    case weight, height, headcirc
}

enum WHOGrowthSex: String, Sendable {
    case boy, girl
}
