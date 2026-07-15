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

    // MARK: - 대시보드 SWR 디스크 캐시 (콜드스타트 무-스피너)
    // 결합도↓: 이 프로퍼티 + DashboardView 주입만 제거하면 캐싱 완전 비활성화.
    let dashboardSnapshotStore: DashboardSnapshotStore

    // MARK: - 달력 SWR 디스크 캐시 (월별 수유 총량 hydrate)
    // 결합도↓: 이 프로퍼티 + DashboardView 주입만 제거하면 달력 캐싱 완전 비활성화.
    let calendarSnapshotStore: CalendarSnapshotStore

    // MARK: - Session State (라우팅 전용)
    let sessionState: SessionState

    // MARK: - Offline Sync 인프라 (feeding 파일럿, Data/Sync 격리)
    // OFF/폴백 시 아예 nil — SwiftData·동기화 런타임 완전 배제. (OFFLINE_TOGGLE_PLAN §1.1)
    private let offline: OfflineInfra?

    /// SwiftData 컨테이너 — OFF/폴백이면 nil (zzippuApp 이 옵셔널로 배선).
    var modelContainer: ModelContainer? { offline?.modelContainer }
    /// 동기화 상태 코디네이터 — OFF/폴백이면 nil (오프라인 UI 가드 대상).
    var syncCoordinator: SyncCoordinator? { offline?.coordinator }
    /// 오프라인 계층 활성 여부 — Feature/UI 는 이 플래그 하나만 본다.
    var isOfflineActive: Bool { offline != nil }

    // MARK: - Active Baby (로그인 후 GET /babies 응답으로 확정)
    var activeBabyId: UUID = UUID() {   // 임시값 — hydrateSession에서 덮어씀
        didSet { offline?.activeBabyBox.id = activeBabyId }
    }

    // MARK: - Init

    init() {
        let api = APIClient(
            tokenProvider: { KeychainTokenStore().load() },
            onUnauthorized: { /* handleUnauthorized는 sessionState 접근이 필요 — 후처리 */ }
        )

        // --- 모드 스위치: 오프라인(Local+Sync) vs 서버-전용(Remote) ---
        // 오프라인 심볼(OfflineInfra·ModelContainer·Local·Syncing)은 이 case .offline 한 곳에서만 등장.
        // (OFFLINE_TOGGLE_PLAN §1.2·§2 — 실패 시 크래시 없이 server-only 강등)
        switch OfflineToggle.resolvedMode() {
        case .offline(let container):
            let infra = OfflineInfra.make(api: api, container: container)
            self.offline = infra
            self.feedingRepository = infra.feedingRepository
        case .serverOnly:
            self.offline = nil
            self.feedingRepository = RemoteFeedingRepository(api: api)
        }

        // ↓ 아래는 모드 무관 — 항상 Remote (S4 전까지)
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
        self.dashboardSnapshotStore = FileDashboardSnapshotStore()
        self.calendarSnapshotStore  = FileCalendarSnapshotStore()
        self.sessionState = SessionState()
    }

    // MARK: - Unauthorized Handler (로그인 화면으로)

    func handleUnauthorized() {
        authRepository.signOut()
        sessionState.setSession(nil)
    }

    // MARK: - Sync 트리거 (Feature 는 이 존재를 모른다 — App 레이어에서만 호출)

    /// 네트워크 감시 시작 (앱 기동 1회). 오프라인→온라인 전환 시 full sync.
    /// server-only(offline == nil)면 옵셔널 체이닝으로 자동 no-op — 호출부 무변경.
    func startNetworkMonitoring() {
        offline?.networkMonitor.start()
    }

    /// 로그인 직후·활성 아기 확정 후·포그라운드 복귀: 초기/전체 동기화.
    /// 무회귀 보장: 로컬이 비어도 첫 pull(since=nil)로 서버 기존 feeding을 채운다.
    /// server-only면 no-op(서버가 진실원천 — 동기화 불필요).
    func triggerFeedingFullSync() {
        offline?.engine.triggerFullSync()
    }

    /// 콜드스타트 완충: 앱 시작·포그라운드 복귀 시 `/health`를 선제 핑해
    /// 스플래시가 보이는 동안 서버(+DB touch로 Neon)를 미리 깨운다.
    /// fire-and-forget — 실패 무시. 첫 실제 API 호출의 콜드 대기를 줄인다.
    func prewarmServer() {
        let url = AuthConfig.baseURL.appendingPathComponent("/health")
        var req = URLRequest(url: url)
        req.timeoutInterval = 60   // 콜드스타트 웨이크업 대기 허용
        URLSession.shared.dataTask(with: req).resume()
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
