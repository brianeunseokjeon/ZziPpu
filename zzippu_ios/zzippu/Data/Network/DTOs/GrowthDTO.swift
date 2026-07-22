// Data/Network/DTOs/GrowthDTO.swift
// 서버 GrowthResponse / CreateGrowthRequest 대응

import Foundation

// MARK: - Response DTO

struct GrowthResponseDTO: Decodable {
    let id: UUID
    let babyId: UUID
    let recordedAt: String          // date(YYYY-MM-DD) — Mapper에서 변환
    let weightG: Int?
    let heightCm: Double?
    let headCircumferenceCm: Double?
    let temperatureC: Double?
    let memo: String?
    let createdAt: Date             // datetime — 자동 디코딩
}

// MARK: - Create Request DTO

struct GrowthCreateRequestDTO: Encodable {
    let recordedAt: String          // YYYY-MM-DD
    let weightG: Int?
    let heightCm: Double?
    let headCircumferenceCm: Double?
    let temperatureC: Double?
    let memo: String?
}

// MARK: - Update Request DTO (PATCH — 전체교체)

/// 서버 PATCH /growth/{id} 대응. recorded_at은 ISO datetime(apiEncoder가 Date→ISO 인코딩).
/// 나머지는 옵셔널이나 편집 시 전체 전송(전체교체 의미).
struct GrowthUpdateRequestDTO: Encodable {
    let recordedAt: Date            // datetime — apiEncoder가 ISO8601로 인코딩
    let weightG: Int?
    let heightCm: Double?
    let headCircumferenceCm: Double?
    let temperatureC: Double?
    let memo: String?
}
