// Data/Network/Mappers/CaregiverMapper.swift
// CaregiverDTO ↔ Domain Entity

import Foundation

enum CaregiverMapper {

    static func toInvite(_ dto: CaregiverInviteResponseDTO) -> CaregiverInvite {
        CaregiverInvite(code: dto.code, expiresAt: dto.expiresAt)
    }

    static func toMember(_ dto: CaregiverMemberResponseDTO) -> CaregiverMember {
        CaregiverMember(userId: dto.userId, role: dto.role, joinedAt: dto.createdAt)
    }
}
