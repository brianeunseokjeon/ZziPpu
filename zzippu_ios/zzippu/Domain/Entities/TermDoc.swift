// Domain/Entities/TermDoc.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

enum TermType: String, Codable, Sendable {
    case service = "service"
    case privacy = "privacy"
}

struct TermDoc: Identifiable, Equatable, Sendable {
    var id: String { "\(type.rawValue)-\(version)" }
    let type: TermType
    let version: String
    let title: String
    let content: String
    let required: Bool
}
