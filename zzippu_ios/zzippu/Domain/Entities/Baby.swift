// Domain/Entities/Baby.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

enum Gender: String, Codable, Sendable, CaseIterable {
    case male    = "male"
    case female  = "female"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .male:    return "남아"
        case .female:  return "여아"
        case .unknown: return "미선택"
        }
    }
}

struct Baby: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let userId: UUID?
    var name: String
    /// 태어난 날짜 + 시각(모두 보유). 인코딩 시 birth_date(날짜) + birth_time(시각)로 분리 전송.
    var birthDate: Date
    var gender: Gender
    var birthWeightG: Int?
    // 출생 측정치(선택). cm 단위 Double.
    var birthHeightCm: Double?
    var birthHeadCircumferenceCm: Double?
    var birthChestCircumferenceCm: Double?
    // 혈액형(선택).
    var bloodType: BloodType?
    var rhFactor: RhFactor?
    var photoUrl: String?          // server-first: URL 문자열 (기존 photoData: Data? 제거)
    let createdAt: Date

    static func new(
        userId: UUID? = nil,
        name: String,
        birthDate: Date,
        gender: Gender,
        birthWeightG: Int? = nil,
        birthHeightCm: Double? = nil,
        birthHeadCircumferenceCm: Double? = nil,
        birthChestCircumferenceCm: Double? = nil,
        bloodType: BloodType? = nil,
        rhFactor: RhFactor? = nil
    ) -> Baby {
        return Baby(
            id: UUID(),
            userId: userId,
            name: name,
            birthDate: birthDate,
            gender: gender,
            birthWeightG: birthWeightG,
            birthHeightCm: birthHeightCm,
            birthHeadCircumferenceCm: birthHeadCircumferenceCm,
            birthChestCircumferenceCm: birthChestCircumferenceCm,
            bloodType: bloodType,
            rhFactor: rhFactor,
            photoUrl: nil,
            createdAt: Date.now
        )
    }
}
