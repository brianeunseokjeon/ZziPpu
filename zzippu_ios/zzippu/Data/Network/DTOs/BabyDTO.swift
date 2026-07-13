// Data/Network/DTOs/BabyDTO.swift
// 서버 BabyResponse / BabyCreateRequest / BabyUpdateRequest 대응

import Foundation

// MARK: - Response DTO

struct BabyResponseDTO: Decodable {
    let id: UUID
    let userId: UUID?
    let name: String
    let birthDate: String          // date(YYYY-MM-DD) — Mapper에서 변환
    let birthTime: String?         // "HH:mm"(24h, KST) — Mapper에서 birthDate와 합침. nullable.
    let gender: String?
    let birthWeightG: Int?
    let birthHeightCm: Double?     // 출생 측정치(선택)
    let birthHeadCircumferenceCm: Double?
    let birthChestCircumferenceCm: Double?
    let bloodType: String?         // A/B/O/AB (선택)
    let rhFactor: String?          // positive/negative (선택)
    let ageDays: Int?              // 서버 파생값 (iOS에서 무시)
    let ageMonths: Int?            // 서버 파생값 (iOS에서 무시)
    let photoUrl: String?
    let createdAt: Date            // datetime — 자동 디코딩
}

// MARK: - Create Request DTO

struct BabyCreateRequestDTO: Encodable {
    let name: String
    let birthDate: String          // YYYY-MM-DD
    let birthTime: String?         // "HH:mm"(24h, KST) — 선택
    let gender: String?
    let birthWeightG: Int?
    let birthHeightCm: Double?
    let birthHeadCircumferenceCm: Double?
    let birthChestCircumferenceCm: Double?
    let bloodType: String?         // A/B/O/AB
    let rhFactor: String?          // positive/negative
}

// MARK: - Update Request DTO

struct BabyUpdateRequestDTO: Encodable {
    let name: String?
    let birthDate: String?         // YYYY-MM-DD
    let birthTime: String?         // "HH:mm"(24h, KST) — 선택
    let gender: String?
    let birthWeightG: Int?
    let birthHeightCm: Double?
    let birthHeadCircumferenceCm: Double?
    let birthChestCircumferenceCm: Double?
    let bloodType: String?         // A/B/O/AB
    let rhFactor: String?          // positive/negative
    let photoUrl: String?
}

// MARK: - Caregiver Join Request DTO

struct CaregiverJoinRequestDTO: Encodable {
    let code: String
}
