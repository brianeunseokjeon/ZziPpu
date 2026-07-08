// Domain/Entities/AuthSession.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

struct AuthSession: Equatable, Sendable {
    let accessToken: String
    let userId: UUID
    var isNewUser: Bool
    var termsRequired: Bool
}
