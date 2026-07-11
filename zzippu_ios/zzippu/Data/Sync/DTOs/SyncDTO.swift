// Data/Sync/DTOs/SyncDTO.swift
// /sync/push · /sync/pull 계약 대응 DTO (feeding 필드 전량 + created/updated/deleted_at)
// snake_case 는 APIClient 의 convertToSnakeCase/convertFromSnakeCase 가 처리.

import Foundation

// MARK: - 공통 레코드 (push 요청 / pull 응답 공용)

struct FeedingSyncDTO: Codable {
    let id: UUID
    let babyId: UUID
    let feedingType: String
    let startedAt: Date
    let endedAt: Date?
    let amountMl: Int?
    let durationMinutes: Int?
    let memo: String?
    let createdAt: Date?
    let updatedAt: Date?     // pull 응답에 포함, push 요청엔 생략 가능(서버 재타임스탬프)
    let deletedAt: Date?
}

// MARK: - Push

struct SyncPushChangesDTO: Encodable {
    let feedings: [FeedingSyncDTO]
}

struct SyncPushRequestDTO: Encodable {
    let changes: SyncPushChangesDTO
}

struct SyncAcceptedDTO: Decodable {
    let kind: String
    let id: UUID
    let updatedAt: Date
}

struct SyncRejectedDTO: Decodable {
    let kind: String?
    let id: UUID?
    let reason: String?
}

struct SyncPushResponseDTO: Decodable {
    let serverTime: Date
    let accepted: [SyncAcceptedDTO]
    let rejected: [SyncRejectedDTO]?
}

// MARK: - Pull

struct SyncPullChangesDTO: Decodable {
    let feedings: [FeedingSyncDTO]?
}

struct SyncPullResponseDTO: Decodable {
    let serverTime: Date
    let changes: SyncPullChangesDTO
}
