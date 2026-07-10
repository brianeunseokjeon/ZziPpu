// Domain/Entities/CaregiverMember.swift
// 공동양육 멤버 — 서버 GET /babies/{id}/caregivers 응답 대응.
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

struct CaregiverMember: Identifiable, Equatable, Sendable {
    /// user_id를 안정 식별자로 사용
    var id: UUID { userId }
    let userId: UUID
    let role: String        // "owner" / "caregiver" 등 서버 문자열
    let joinedAt: Date

    /// 역할 한글 표기 (미상은 원문 노출)
    var roleLabel: String {
        switch role {
        case "owner":     return "관리자"
        case "caregiver": return "공동양육자"
        default:          return role
        }
    }
}
