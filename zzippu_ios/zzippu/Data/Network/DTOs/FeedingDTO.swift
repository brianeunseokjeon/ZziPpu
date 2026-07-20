// Data/Network/DTOs/FeedingDTO.swift
// 서버 FeedingResponse / FeedingCreateRequest / FeedingUpdateRequest 대응

import Foundation

// MARK: - Response DTO

struct FeedingResponseDTO: Decodable {
    let id: UUID
    let babyId: UUID
    let feedingType: String         // FeedingType raw value
    let startedAt: Date             // datetime — 자동 디코딩
    let endedAt: Date?
    let amountMl: Int?
    let durationMinutes: Int?
    let memo: String?
    let didVomit: Bool?          // 구서버 응답엔 없을 수 있어 옵셔널(매퍼에서 ?? false)
    let createdAt: Date
}

// MARK: - Create Request DTO

struct FeedingCreateRequestDTO: Encodable {
    let feedingType: String
    let startedAt: Date
    let endedAt: Date?
    let amountMl: Int?
    let durationMinutes: Int?
    let memo: String?
    let didVomit: Bool
}

// MARK: - Update Request DTO

struct FeedingUpdateRequestDTO: Encodable {
    let feedingType: String?
    let startedAt: Date?
    let endedAt: Date?
    let amountMl: Int?
    let durationMinutes: Int?
    let memo: String?
    let didVomit: Bool?
}
