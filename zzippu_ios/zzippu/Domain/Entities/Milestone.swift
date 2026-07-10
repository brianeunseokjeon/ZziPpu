// Domain/Entities/Milestone.swift
// 발달 마일스톤(50일·백일·돌 등) — Foundation only.

import Foundation

struct Milestone: Identifiable, Equatable, Sendable {
    let days: Int
    let label: String
    let emoji: String
    let category: Category
    let description: String

    var id: Int { days }

    enum Category: String, Sendable {
        case celebration
        case checkup
        case developmental
    }
}
