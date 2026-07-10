// Domain/Entities/CaregiverInvite.swift
// 공동양육자 초대코드 — 서버 POST /babies/{id}/caregivers/invite 응답 대응.
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

struct CaregiverInvite: Equatable, Sendable {
    let code: String
    let expiresAt: Date
}
