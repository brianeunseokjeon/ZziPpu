// Domain/Entities/Baby.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

enum Gender: String, Codable, Sendable, CaseIterable {
    case male    = "male"
    case female  = "female"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .male:    return "남아"
        case .female:  return "여아"
        case .unknown: return "미선택"
        }
    }
}

struct Baby: Identifiable, Equatable, Sendable {
    let id: UUID
    let userId: UUID?
    var name: String
    var birthDate: Date
    var gender: Gender
    var birthWeightG: Int?
    var photoData: Data?
    let createdAt: Date
    var updatedAt: Date
    var syncState: SyncState
    var deletedAt: Date?

    static func new(
        userId: UUID? = nil,
        name: String,
        birthDate: Date,
        gender: Gender,
        birthWeightG: Int? = nil
    ) -> Baby {
        let now = Date.now
        return Baby(
            id: UUID(),
            userId: userId,
            name: name,
            birthDate: birthDate,
            gender: gender,
            birthWeightG: birthWeightG,
            photoData: nil,
            createdAt: now,
            updatedAt: now,
            syncState: .localOnly,
            deletedAt: nil
        )
    }
}
