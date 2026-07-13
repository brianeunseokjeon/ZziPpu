// Domain/UseCases/ClassifyGrowthPercentileUseCase.swift
// 실측값 + WHO 밴드 → 5카테고리 백분위 판정(순수 로직, 색 모름).
// 기획서 §2-2 컷오프: veryLow(<p3) / low(p3~p15) / normal(p15~p85) / high(p85~p97) / veryHigh(>p97).
// 색/표현은 View. Domain은 카테고리 + 완곡·비진단 라벨/보조문구(문서 카피 그대로)만 제공.
// Foundation only — SwiftUI/SwiftData import 금지.

import Foundation

// MARK: - GrowthPercentileCategory

/// WHO 백분위 위치 5카테고리. 기존 6밴드에서 p15~p85(±1SD)를 normal로 병합한 정규화 버전.
enum GrowthPercentileCategory: String, Sendable, CaseIterable {
    case veryLow   // < 3 %ile   (WHO −2SD 미만 · 스크리닝 하한)
    case low       // 3 ~ 15 %ile (−2SD~−1SD · 정상 범위 내 낮은 편)
    case normal    // 15 ~ 85 %ile (±1SD · 또래 평균/보통)
    case high      // 85 ~ 97 %ile (+1SD~+2SD · 정상 범위 내 높은 편)
    case veryHigh  // > 97 %ile  (WHO +2SD 초과 · 스크리닝 상한)

    /// 배지 라벨 — 지표(체중/키) 문맥에 따라 "작은/큰 편" 어휘를 맞춤(§2-2 완곡 톤).
    /// - metricNoun: "체중" | "키" 등. "작은/큰"은 키·체중 공통으로 자연스러워 그대로 사용.
    func badgeLabel() -> String {
        switch self {
        case .veryLow:  return "또래보다 작은 편 · 3백분위 미만"
        case .low:      return "약 3~15백분위 · 낮은 편"
        case .normal:   return "정상 범위 · 또래 평균 수준"
        case .high:     return "약 85~97백분위 · 높은 편"
        case .veryHigh: return "또래보다 큰 편 · 97백분위 초과"
        }
    }

    /// 보조 문구 — 완곡·비진단. veryLow/veryHigh는 상담 권유를 동반(§2-2).
    var supportingText: String {
        switch self {
        case .veryLow:
            return "또래보다 작은 편이에요. 개인차는 정상이지만, 걱정되면 소아청소년과 상담을 권해드려요."
        case .low:
            return "정상 범위 안에서 낮은 편이에요. 성장 속도가 꾸준하면 대개 괜찮아요."
        case .normal:
            return "또래 평균 수준이에요. 개인차는 정상이며 정밀 진단은 아니에요."
        case .high:
            return "정상 범위 안에서 높은 편이에요. 성장 속도가 꾸준하면 대개 괜찮아요."
        case .veryHigh:
            return "또래보다 큰 편이에요. 개인차는 정상이지만, 걱정되면 소아청소년과 상담을 권해드려요."
        }
    }

    /// 상담 권유가 필요한 경계(스크리닝 하/상한).
    var suggestsConsultation: Bool {
        self == .veryLow || self == .veryHigh
    }
}

// MARK: - ClassifyGrowthPercentileUseCase

/// 실측 최신값을 WHO 밴드에 대입해 5카테고리로 판정하는 순수 UseCase.
/// 색·표현 무관 — 오직 컷오프 판정만 담당(클린아키텍처: Domain은 색 모름).
struct ClassifyGrowthPercentileUseCase {

    /// - Parameters:
    ///   - value: 실측 최신값(지표 단위).
    ///   - band: 해당 월령·성별의 WHO 백분위 밴드.
    /// - Returns: §2-2 5카테고리.
    func callAsFunction(value: Double, band: WHOBandSpec) -> GrowthPercentileCategory {
        switch value {
        case ..<band.p3:          return .veryLow
        case band.p3..<band.p15:  return .low
        case band.p15..<band.p85: return .normal   // p15~p50 + p50~p85 병합
        case band.p85..<band.p97: return .high
        default:                  return .veryHigh
        }
    }
}
