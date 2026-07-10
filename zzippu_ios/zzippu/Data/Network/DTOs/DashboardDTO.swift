// Data/Network/DTOs/DashboardDTO.swift
// Dashboard API DTO — /api/v1/babies/{id}/dashboard/daily + /predictions

import Foundation

// MARK: - Daily Summary Response DTO

struct DailySummaryResponseDTO: Decodable {
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
}

// MARK: - Prediction Response DTO

struct PredictionResponseDTO: Decodable {
    let lastFeedingAt:           Date?
    let nextFeedingAt:           Date?
    let feedingIntervalMinutes:  Int?
    let feedingBasedOn:          Int
    let lastSleepEndedAt:        Date?
    let nextSleepAt:             Date?
    let awakeWindowMinutes:      Int?
    let sleepBasedOn:            Int
}
