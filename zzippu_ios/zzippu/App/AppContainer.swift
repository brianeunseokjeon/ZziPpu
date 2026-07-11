// App/AppContainer.swift
// Composition Root — 모든 구체 Repository를 생성·보관

import Foundation
import Observation
import SwiftData

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

    // MARK: - 정적 가이드 데이터 (소아과 권장 · WHO 성장) — Data 레이어 번들 로더
    let guidelineRepository:   GuidelineRepository

    // MARK: - Session State (라우팅 전용)
    let sessionState: SessionState

    // MARK: - Offline Sync 인프라 (feeding 파일럿, Data/Sync 격리)
    let modelContainer: ModelContainer
    let syncCoordinator: SyncCoordinator
    let feedingSyncEngine: FeedingSyncEngine
    private let networkMonitor: NetworkMonitor
    /// 동기화 엔진이 참조하는 활성 아기 id 상자 (init 중 self 캡처 회피)
    private let activeBabyBox: ActiveBabyBox

    // MARK: - Active Baby (로그인 후 GET /babies 응답으로 확정)
    var activeBabyId: UUID = UUID() {   // 임시값 — hydrateSession에서 덮어씀
        didSet { activeBabyBox.id = activeBabyId }
    }

    // MARK: - Init

    init() {
        let api = APIClient(
            tokenProvider: { KeychainTokenStore().load() },
            onUnauthorized: { /* handleUnauthorized는 sessionState 접근이 필요 — 후처리 */ }
        )

        // --- feeding 오프라인 영속 + 동기화 엔진 배선 (S0~S3) ---
        let container = AppModelContainer.make()
        self.modelContainer = container
        let localFeeding = LocalFeedingRepository(modelContainer: container)
        let coordinator = SyncCoordinator()
        self.syncCoordinator = coordinator

        // babyIdProvider 는 self.activeBabyId 를 지연 참조. init 중 self 캡처 회피 위해 box 사용.
        let babyBox = ActiveBabyBox()
        let engine = FeedingSyncEngine(
            store: localFeeding,
            dataSource: FeedingSyncDataSource(api: api),
            coordinator: coordinator,
            babyIdProvider: { babyBox.id }
        )
        self.feedingSyncEngine = engine
        self.activeBabyBox = babyBox
        self.networkMonitor = NetworkMonitor { [engine] in engine.triggerFullSync() }

        // feeding 만 Local(+동기화 데코레이터)로 주입. 나머지는 Remote 유지(혼재 허용).
        self.feedingRepository = SyncingFeedingRepository(local: localFeeding, engine: engine)
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
        self.guidelineRepository   = BundleGuidelineRepository()
        self.sessionState = SessionState()
    }

    // MARK: - Unauthorized Handler (로그인 화면으로)

    func handleUnauthorized() {
        authRepository.signOut()
        sessionState.setSession(nil)
    }

    // MARK: - Sync 트리거 (Feature 는 이 존재를 모른다 — App 레이어에서만 호출)

    /// 네트워크 감시 시작 (앱 기동 1회). 오프라인→온라인 전환 시 full sync.
    func startNetworkMonitoring() {
        networkMonitor.start()
    }

    /// 로그인 직후·활성 아기 확정 후·포그라운드 복귀: 초기/전체 동기화.
    /// 무회귀 보장: 로컬이 비어도 첫 pull(since=nil)로 서버 기존 feeding을 채운다.
    func triggerFeedingFullSync() {
        feedingSyncEngine.triggerFullSync()
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

/// 활성 아기 id 를 스레드 안전하게 담는 상자 — SyncEngine 의 @Sendable babyIdProvider 가 참조.
/// AppContainer 는 @Observable(비-Sendable)이라 엔진에 직접 넘길 수 없으므로 이 상자로 우회.
final class ActiveBabyBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _id: UUID?
    var id: UUID? {
        get { lock.lock(); defer { lock.unlock() }; return _id }
        set { lock.lock(); _id = newValue; lock.unlock() }
    }
}
