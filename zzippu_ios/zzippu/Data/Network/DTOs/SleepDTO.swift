// Data/Network/DTOs/SleepDTO.swift
// 서버 SleepResponse / SleepStartRequest / SleepEndRequest 대응

import Foundation

// MARK: - Response DTO

struct SleepResponseDTO: Decodable {
    let id: UUID
    let babyId: UUID
    let startedAt: Date
    let endedAt: Date?
    let durationMinutes: Int?
    let memo: String?
    let createdAt: Date
}

// MARK: - Start Request DTO

struct SleepStartRequestDTO: Encodable {
    let startedAt: Date
    let memo: String?
}

// MARK: - End Request DTO

struct SleepEndRequestDTO: Encodable {
    let endedAt: Date
}
