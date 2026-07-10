// Data/Network/DTOs/DevelopmentDTO.swift
// 서버 development_router 스키마 대응 (snake_case → convertFromSnakeCase).

import Foundation

struct ParentActionDTO: Decodable {
    let icon: String
    let title: String
    let detail: String
    let source: String
    let priority: String   // high | medium | low
}

struct DevelopmentStageDTO: Decodable {
    let ageRangeDays: [Int]   // 서버 tuple[int,int] → JSON 배열 [min, max]
    let label: String
    let summary: String
    let grossMotor: [String]
    let fineMotor: [String]
    let cognition: [String]
    let language: [String]
    let social: [String]
    let selfCare: [String]
    let parentActions: [ParentActionDTO]
    let warningSigns: [String]
    let feedingSummary: String
    let sleepSummary: String
    let playSummary: String
    let sources: [String]
}

struct CurrentStageBundleDTO: Decodable {
    let current: DevelopmentStageDTO
    let previous: DevelopmentStageDTO?
    let next: DevelopmentStageDTO?
    let ageDays: Int
}

struct MilestoneDTO: Decodable {
    let days: Int
    let label: String
    let emoji: String
    let category: String
    let description: String
}
