// App/OfflineInfra.swift
// 오프라인 인프라 캡슐화 — modelContainer·syncCoordinator·feedingSyncEngine·networkMonitor·activeBabyBox 묶음.
// 오프라인 모드일 때만 생성(AppContainer 의 case .offline 한 분기). OFF/폴백이면 아예 nil.
//
// 목적: AppContainer 본문에서 오프라인 심볼 노출 최소화 → 제거 시 이 묶음 참조만 지우면 됨.
// OFFLINE_TOGGLE_PLAN §1.1·§2.

import Foundation
import SwiftData

/// 오프라인 저장·동기화에 필요한 모든 런타임 객체 묶음.
struct OfflineInfra {
    let modelContainer: ModelContainer
    let coordinator: SyncCoordinator
    let engine: FeedingSyncEngine
    let networkMonitor: NetworkMonitor
    /// 활성 아기 id 상자(엔진 @Sendable babyIdProvider 가 참조 — self 캡처 회피).
    let activeBabyBox: ActiveBabyBox

    /// feeding 리포지토리는 데코레이터(Syncing)로 조립해 반환.
    let feedingRepository: FeedingRepository

    /// 컨테이너 생성 성공 후 엔진·모니터·리포지토리를 배선한다.
    static func make(api: APIClient, container: ModelContainer) -> OfflineInfra {
        let localFeeding = LocalFeedingRepository(modelContainer: container)
        let coordinator = SyncCoordinator()

        let babyBox = ActiveBabyBox()
        let engine = FeedingSyncEngine(
            store: localFeeding,
            dataSource: FeedingSyncDataSource(api: api),
            coordinator: coordinator,
            babyIdProvider: { babyBox.id }
        )
        let monitor = NetworkMonitor { [engine] in engine.triggerFullSync() }

        return OfflineInfra(
            modelContainer: container,
            coordinator: coordinator,
            engine: engine,
            networkMonitor: monitor,
            activeBabyBox: babyBox,
            feedingRepository: SyncingFeedingRepository(local: localFeeding, engine: engine)
        )
    }
}
