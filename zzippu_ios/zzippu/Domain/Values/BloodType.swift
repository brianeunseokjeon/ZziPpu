// Domain/Values/BloodType.swift
// Foundation only — SwiftUI/SwiftData import 금지
//
// 혈액형(ABO) + Rh 인자. 백엔드 계약: blood_type(A/B/O/AB), rh_factor(positive/negative).
// 전부 nullable — 미선택 허용.

import Foundation

/// ABO 혈액형. 서버 계약: 대문자 문자열 A/B/O/AB.
enum BloodType: String, Codable, Sendable, CaseIterable {
    case a  = "A"
    case b  = "B"
    case o  = "O"
    case ab = "AB"

    /// 표기용(선택 세그먼트 라벨과 동일).
    var displayName: String {
        switch self {
        case .a:  return "A"
        case .b:  return "B"
        case .o:  return "O"
        case .ab: return "AB"
        }
    }
}

/// Rh 인자. 서버 계약: positive/negative.
enum RhFactor: String, Codable, Sendable, CaseIterable {
    case positive = "positive"
    case negative = "negative"

    /// 표기용(+/-).
    var displayName: String {
        switch self {
        case .positive: return "+"
        case .negative: return "-"
        }
    }
}
