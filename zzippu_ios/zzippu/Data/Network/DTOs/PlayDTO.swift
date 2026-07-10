// Data/Network/DTOs/PlayDTO.swift
// 서버 PlayResponse / PlayCreateRequest 대응

import Foundation

// MARK: - Response DTO

struct PlayResponseDTO: Decodable {
    let id: UUID
    let babyId: UUID
    let playType: String
    let startedAt: Date
    let endedAt: Date?
    let durationMinutes: Int?
    let memo: String?
    let createdAt: Date
}

// MARK: - Create Request DTO

struct PlayCreateRequestDTO: Encodable {
    let playType: String
    let startedAt: Date
    let endedAt: Date?
    let durationMinutes: Int?
    let memo: String?
}
