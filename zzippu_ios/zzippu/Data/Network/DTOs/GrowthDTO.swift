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
    let memo: String?
    let createdAt: Date             // datetime — 자동 디코딩
}

// MARK: - Create Request DTO

struct GrowthCreateRequestDTO: Encodable {
    let recordedAt: String          // YYYY-MM-DD
    let weightG: Int?
    let heightCm: Double?
    let headCircumferenceCm: Double?
    let memo: String?
}
