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
}

// MARK: - Update Request DTO

struct FeedingUpdateRequestDTO: Encodable {
    let feedingType: String?
    let startedAt: Date?
    let endedAt: Date?
    let amountMl: Int?
    let durationMinutes: Int?
    let memo: String?
}
