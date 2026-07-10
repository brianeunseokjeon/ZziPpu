// Domain/Repositories/DashboardRepository.swift
// Foundation only — SwiftUI/SwiftData import 금지

import Foundation

protocol DashboardRepository {
    func dailySummary(babyId: UUID, date: Date) async throws -> DailySummary
    func predictions(babyId: UUID) async throws -> FeedingPrediction
}
