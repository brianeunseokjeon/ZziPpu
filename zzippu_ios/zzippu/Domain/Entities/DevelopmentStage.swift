// Domain/Entities/DevelopmentStage.swift
// 발달 시기(정적 콘텐츠) — Foundation only. SwiftUI/SwiftData import 금지.

import Foundation

/// 발달 영역 (K-DST 6영역).
enum DevelopmentArea: String, CaseIterable, Sendable {
    case grossMotor
    case fineMotor
    case cognition
    case language
    case social
    case selfCare

    var label: String {
        switch self {
        case .grossMotor: return "대근육"
        case .fineMotor:  return "소근육"
        case .cognition:  return "인지"
        case .language:   return "언어"
        case .social:     return "사회성"
        case .selfCare:   return "자조"
        }
    }
}

/// 부모 행동 가이드 항목.
struct ParentAction: Identifiable, Equatable, Sendable {
    let id: UUID
    let icon: String
    let title: String
    let detail: String
    let source: String
    let priority: Priority

    enum Priority: String, Sendable {
        case high, medium, low
    }
}

/// 연령 구간별 발달 이정표 (읽기 전용 콘텐츠).
struct DevelopmentStage: Identifiable, Equatable, Sendable {
    /// [최소일수, 최대일수] — 구간 시작일을 안정적 식별자로 사용.
    let ageRangeDays: ClosedRange<Int>
    let label: String
    let summary: String

    // K-DST 6영역
    let grossMotor: [String]
    let fineMotor: [String]
    let cognition: [String]
    let language: [String]
    let social: [String]
    let selfCare: [String]

    let parentActions: [ParentAction]
    let warningSigns: [String]
    let feedingSummary: String
    let sleepSummary: String
    let playSummary: String
    let sources: [String]

    var id: Int { ageRangeDays.lowerBound }

    /// 영역별 접근 헬퍼 (뷰에서 섹션 반복용).
    func items(for area: DevelopmentArea) -> [String] {
        switch area {
        case .grossMotor: return grossMotor
        case .fineMotor:  return fineMotor
        case .cognition:  return cognition
        case .language:   return language
        case .social:     return social
        case .selfCare:   return selfCare
        }
    }
}

/// 현재 시기 + 이전/다음 시기 묶음 (네비게이션용).
struct DevelopmentStageBundle: Equatable, Sendable {
    let current: DevelopmentStage
    let previous: DevelopmentStage?
    let next: DevelopmentStage?
    let ageDays: Int
}
