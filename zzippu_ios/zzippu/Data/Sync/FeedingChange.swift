// Data/Sync/FeedingChange.swift
// 동기화 엔진 ↔ 로컬 스토어/원격 데이터소스 사이를 오가는 feeding 레코드의 Sendable 전송체.
// SwiftData @Model(스레드 구속)을 액터 밖으로 새지 않게 하는 경계 값.

import Foundation

/// feeding 한 레코드의 전 필드 + sync 메타 (tombstone 포함).
struct FeedingChange: Sendable {
    let id: UUID
    let babyId: UUID
    let feedingType: String
    let startedAt: Date
    let endedAt: Date?
    let amountMl: Int?
    let durationMinutes: Int?
    let memo: String?
    let didVomit: Bool
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
}
