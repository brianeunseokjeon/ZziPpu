// App/AppContainer.swift
// Composition Root — 모든 구체 Repository를 생성·보관

import Foundation
import SwiftData
import Observation

@Observable
final class AppContainer {
    // MARK: - Infrastructure
    let modelContext: ModelContext

    // MARK: - Repositories (Domain 프로토콜 타입으로 보관)
    let feedingRepository: FeedingRepository
    let babyRepository: BabyRepository
    let growthRepository: GrowthRepository
    let authRepository: AuthRepository

    // MARK: - Session State (라우팅 전용)
    let sessionState: SessionState

    // MARK: - Active Baby
    var activeBabyId: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.feedingRepository = SwiftDataFeedingRepository(context: modelContext)
        self.babyRepository    = SwiftDataBabyRepository(context: modelContext)
        self.growthRepository  = SwiftDataGrowthRepository(context: modelContext)
        self.authRepository    = AuthRepositoryImpl(
            remote: AuthRemoteDataSource(),
            tokenStore: KeychainTokenStore()
        )
        self.sessionState = SessionState()
    }

    // MARK: - Preview Factory

    @MainActor
    static var preview: AppContainer {
        let container = try! ModelContainer.makePreviewContainer()
        let ctx = container.mainContext
        let appContainer = AppContainer(modelContext: ctx)

        // 시드 데이터
        let babyId = appContainer.activeBabyId
        let samples: [Feeding] = [
            .new(babyId: babyId, type: .formula, amountMl: 120, startedAt: Date().addingTimeInterval(-3600)),
            .new(babyId: babyId, type: .breastLeft, durationMinutes: 15, startedAt: Date().addingTimeInterval(-7200)),
        ]
        for sample in samples {
            try? appContainer.feedingRepository.create(sample)
        }
        return appContainer
    }
}
