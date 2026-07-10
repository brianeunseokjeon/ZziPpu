// Data/Repositories/RemoteDashboardRepository.swift
// DashboardRepository 프로토콜 구현

import Foundation

final class RemoteDashboardRepository: DashboardRepository {

    private let dataSource: RemoteDashboardDataSource

    init(api: APIClient) {
        self.dataSource = RemoteDashboardDataSource(api: api)
    }

    // MARK: - DashboardRepository

    func dailySummary(babyId: UUID, date: Date) async throws -> DailySummary {
        let dateStr = ISO8601DateFormatter.yyyyMMdd.string(from: date)
        let dto = try await dataSource.dailySummary(babyId: babyId, date: dateStr)
        return DailySummary(
            totalFeedingMl:    dto.totalFeedingMl,
            feedingCount:      dto.feedingCount,
            totalSleepMinutes: dto.totalSleepMinutes,
            sleepCount:        dto.sleepCount,
            diaperCount:       dto.diaperCount,
            poopCount:         dto.poopCount,
            peeCount:          dto.peeCount,
            totalPlayMinutes:  dto.totalPlayMinutes,
            tummyTimeMinutes:  dto.tummyTimeMinutes,
            lastFeedingAt:     dto.lastFeedingAt,
            lastDiaperAt:      dto.lastDiaperAt,
            lastSleepAt:       dto.lastSleepAt
        )
    }

    func predictions(babyId: UUID) async throws -> FeedingPrediction {
        let dto = try await dataSource.predictions(babyId: babyId)
        return FeedingPrediction(
            lastFeedingAt:          dto.lastFeedingAt,
            nextFeedingAt:          dto.nextFeedingAt,
            feedingIntervalMinutes: dto.feedingIntervalMinutes,
            feedingBasedOn:         dto.feedingBasedOn,
            lastSleepEndedAt:       dto.lastSleepEndedAt,
            nextSleepAt:            dto.nextSleepAt,
            awakeWindowMinutes:     dto.awakeWindowMinutes,
            sleepBasedOn:           dto.sleepBasedOn
        )
    }
}

// MARK: - ISO8601DateFormatter extension

private extension ISO8601DateFormatter {
    static let yyyyMMdd: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return f
    }()
}
