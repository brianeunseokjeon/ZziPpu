// Data/Network/DTOs/DiaperDTO.swift
// 서버 DiaperResponse / DiaperCreateRequest 대응

import Foundation

// MARK: - Response DTO

struct DiaperResponseDTO: Decodable {
    let id: UUID
    let babyId: UUID
    let recordedAt: Date
    let diaperType: String
    let stoolColor: String?
    let stoolState: String?
    let memo: String?
    let createdAt: Date
}

// MARK: - Create Request DTO

struct DiaperCreateRequestDTO: Encodable {
    let recordedAt: Date
    let diaperType: String
    let stoolColor: String?
    let stoolState: String?
    let memo: String?
}
