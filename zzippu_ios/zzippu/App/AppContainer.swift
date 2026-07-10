// App/AppContainer.swift
// Composition Root — 모든 구체 Repository를 생성·보관

import Foundation
import Observation

@Observable
final class AppContainer {

    // MARK: - Repositories (Domain 프로토콜 타입으로 보관)
    let feedingRepository:   FeedingRepository
    let babyRepository:      BabyRepository
    let growthRepository:    GrowthRepository
    let authRepository:      AuthRepository
    let sleepRepository:     SleepRepository
    let diaperRepository:    DiaperRepository
    let playRepository:      PlayRepository
    let dashboardRepository: DashboardRepository
    let developmentRepository: DevelopmentRepository
    let vaccinationRepository: VaccinationRepository
    let caregiverRepository:   CaregiverRepository

    // MARK: - Session State (라우팅 전용)
    let sessionState: SessionState

    // MARK: - Active Baby (로그인 후 GET /babies 응답으로 확정)
    var activeBabyId: UUID = UUID()   // 임시값 — hydrateSession에서 덮어씀

    // MARK: - Init

    init() {
        let api = APIClient(
            tokenProvider: { KeychainTokenStore().load() },
            onUnauthorized: { /* handleUnauthorized는 sessionState 접근이 필요 — 후처리 */ }
        )
        self.feedingRepository = RemoteFeedingRepository(api: api)
        self.babyRepository    = RemoteBabyRepository(api: api)
        self.growthRepository  = RemoteGrowthRepository(api: api)
        self.authRepository    = AuthRepositoryImpl(
            remote: AuthRemoteDataSource(),
            tokenStore: KeychainTokenStore()
        )
        self.sleepRepository     = RemoteSleepRepository(api: api)
        self.diaperRepository    = RemoteDiaperRepository(api: api)
        self.playRepository      = RemotePlayRepository(api: api)
        self.dashboardRepository = RemoteDashboardRepository(api: api)
        self.developmentRepository = RemoteDevelopmentRepository(api: api)
        self.vaccinationRepository = RemoteVaccinationRepository(api: api)
        self.caregiverRepository   = RemoteCaregiverRepository(api: api)
        self.sessionState = SessionState()
    }

    // MARK: - Unauthorized Handler (로그인 화면으로)

    func handleUnauthorized() {
        authRepository.signOut()
        sessionState.setSession(nil)
    }

    // MARK: - Preview Factory (Mock 리포지토리 — 네트워크 미접속)

    @MainActor
    static var preview: AppContainer {
        let container = AppContainer()
        // 프리뷰용 시드: 네트워크 없이 동작하려면 MockRepository 필요
        // (현재 RemoteRepository는 실제 네트워크 — 프리뷰는 빈 상태로 표시)
        return container
    }
}
