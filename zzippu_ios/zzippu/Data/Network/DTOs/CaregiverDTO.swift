// Data/Network/DTOs/CaregiverDTO.swift
// 서버 InviteResponse / CaregiverMemberResponse 대응.

import Foundation

// MARK: - Invite Response DTO

struct CaregiverInviteResponseDTO: Decodable {
    let code: String
    let expiresAt: Date        // datetime — 자동 디코딩
}

// MARK: - Member Response DTO

struct CaregiverMemberResponseDTO: Decodable {
    let userId: UUID
    let role: String
    let createdAt: Date        // datetime — 자동 디코딩
}
