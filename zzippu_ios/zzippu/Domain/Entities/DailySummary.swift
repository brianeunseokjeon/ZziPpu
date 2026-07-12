// Domain/Entities/DailySummary.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

// MARK: - DailySummary (서버 집계 결과)

struct DailySummary: Equatable, Sendable, Codable {
    let totalFeedingMl:    Int
    let feedingCount:      Int
    let totalSleepMinutes: Int
    let sleepCount:        Int
    let diaperCount:       Int
    let poopCount:         Int
    let peeCount:          Int
    let totalPlayMinutes:  Int
    let tummyTimeMinutes:  Int
    let lastFeedingAt:     Date?
    let lastDiaperAt:      Date?
    let lastSleepAt:       Date?

    static let empty = DailySummary(
        totalFeedingMl: 0, feedingCount: 0,
        totalSleepMinutes: 0, sleepCount: 0,
        diaperCount: 0, poopCount: 0, peeCount: 0,
        totalPlayMinutes: 0, tummyTimeMinutes: 0,
        lastFeedingAt: nil, lastDiaperAt: nil, lastSleepAt: nil
    )
}

// MARK: - FeedingPrediction

struct FeedingPrediction: Equatable, Sendable, Codable {
    let lastFeedingAt:          Date?
    let nextFeedingAt:          Date?
    let feedingIntervalMinutes: Int?
    let feedingBasedOn:         Int
    let lastSleepEndedAt:       Date?
    let nextSleepAt:            Date?
    let awakeWindowMinutes:     Int?
    let sleepBasedOn:           Int

    static let empty = FeedingPrediction(
        lastFeedingAt: nil, nextFeedingAt: nil,
        feedingIntervalMinutes: nil, feedingBasedOn: 0,
        lastSleepEndedAt: nil, nextSleepAt: nil,
        awakeWindowMinutes: nil, sleepBasedOn: 0
    )
}

// MARK: - MetricPoint (집계 데이터 포인트, 차트용)

struct MetricPoint: Identifiable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let value: Double
    let label: String

    init(date: Date, value: Double, label: String = "") {
        self.id    = UUID()
        self.date  = date
        self.value = value
        self.label = label
    }
}
