// Data/Network/DTOs/CareLogDTO.swift
// 서버 CareLogResponse / CareLogCreateRequest / CareLogUpdateRequest 대응
// snake_case ↔ camelCase 는 APIClient 의 convert 전략이 처리(recordedAt↔recorded_at 등).

import Foundation

// MARK: - Response DTO

struct CareLogResponseDTO: Decodable {
    let id: UUID
    let babyId: UUID
    let category: String
    let name: String?
    let dose: String?
    let recordedAt: Date
    let memo: String?
    let createdAt: Date
}

// MARK: - Create Request DTO

struct CareLogCreateRequestDTO: Encodable {
    let category: String
    let name: String?
    let dose: String?
    let recordedAt: Date
    let memo: String?
}

// MARK: - Update Request DTO

struct CareLogUpdateRequestDTO: Encodable {
    let category: String        // 백엔드 필수(카테고리 불변이라도 전송) — 누락 시 422
    let name: String?
    let dose: String?
    let recordedAt: Date        // 백엔드 필수 — 옵셔널 아님
    let memo: String?
}
